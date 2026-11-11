import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_samsung_tizen/remote_samsung_tizen.dart';
import 'package:remote_samsung_tizen/src/samsung_controller.dart';
import 'package:test/test.dart';

import 'support/samsung_test_credentials.dart';
import 'support/samsung_test_transport.dart';

void main() {
  test(
    'pairs, sends commands, handles loss and reconnects with its token',
    () async {
      final credentials = SamsungTestCredentials();
      final transports = <SamsungTestTransport>[];
      final requests = <Uri>[];
      final definition = SamsungProvider(credentials: credentials).definition;
      final device = definition.manualSetup!.manualDeviceFactory(
        address: '192.168.1.42',
        name: 'Living room',
        legacy: false,
        allowInsecurePointer: false,
        certificate: 'AQID',
      );
      final remote = SamsungController(
        device,
        credentials,
        () async {},
        false,
        bindings: DriverBindings({
          'navigation-enter': 'KEY_ENTER',
          'volume-up': 'KEY_POWER',
        }),
        openTransport: (uri, pin) async {
          expect(pin, 'AQID');
          requests.add(uri);
          final transport = SamsungTestTransport();
          transports.add(transport);
          transport.receive({'event': 'ms.remote.touchEnable'});
          transport.receive({
            'event': 'ms.channel.connect',
            'data': {if (requests.length == 1) 'token': '123456'},
          });
          return transport;
        },
      );
      addTearDown(remote.dispose);
      final states = <DeviceConnectionState>[];
      final subscription = remote.connectionStates.listen(states.add);
      addTearDown(subscription.cancel);

      await remote.connect();
      expect(states, contains(DeviceConnectionState.pairing));
      expect(requests.single.scheme, 'wss');
      expect(requests.single.port, 8002);
      expect(requests.single.queryParameters, isNot(contains('token')));
      expect(remote.supports(RemoteCapability.applications), isTrue);
      expect(remote.supports(RemoteCapability.tvSettings), isTrue);
      expect((await remote.applications()).single.name, 'Example');

      await remote.press(NavigationKey.enter);
      await remote.volumeUp();
      final write = transports.single.launchWrite = Completer<void>();
      final launch = remote.launchApplication('123');
      final rejected = expectLater(
        launch,
        throwsA(
          isA<RemoteException>().having(
            (error) => error.code,
            'code',
            'network',
          ),
        ),
      );
      write.completeError(StateError('test transport write rejected'));
      await rejected;
      transports.single.launchWrite = null;
      await remote.sendKey(RemoteKey.source);
      await remote.sendKey(RemoteKey.settings);
      await remote.sendKey(RemoteKey.mute);
      await remote.sendKey(RemoteKey.digit3);
      await remote.launchApplication('456');
      await remote.launchApplication('123');
      await remote.powerOff();
      expect(
        transports.single.sent.map((frame) => frame['params']),
        containsAllInOrder([
          containsPair('DataOfCmd', 'KEY_ENTER'),
          containsPair('DataOfCmd', 'KEY_VOLUP'),
          containsPair('DataOfCmd', 'KEY_SOURCE'),
          containsPair('DataOfCmd', 'KEY_MENU'),
          containsPair('DataOfCmd', 'KEY_MUTE'),
          containsPair('DataOfCmd', 'KEY_3'),
          containsPair('data', containsPair('appId', '456')),
          containsPair('event', 'ed.apps.launch'),
          containsPair('DataOfCmd', 'KEY_POWER'),
        ]),
      );
      await expectLater(
        remote.launchApplication('not a valid id!'),
        throwsA(isA<RemoteException>()),
      );

      final disconnected = remote.connectionStates.firstWhere(
        (state) => state == DeviceConnectionState.disconnected,
      );
      await transports.single.close();
      await disconnected;
      await remote.connect();
      expect(requests.last.queryParameters['token'], '123456');
      expect(remote.state, DeviceConnectionState.connected);
    },
  );

  test(
    'requires certificate approval and never reuses a token after pin changes',
    () async {
      final credentials = SamsungTestCredentials()
        ..saved = '{"pin":"AQID","token":"old"}';
      final definition = SamsungProvider(credentials: credentials).definition;
      final device = definition.manualSetup!.manualDeviceFactory(
        address: '192.168.1.42',
        name: '',
        legacy: false,
        allowInsecurePointer: false,
      );
      final unpinned = definition.createController(device);
      addTearDown(unpinned.dispose);
      await expectLater(
        unpinned.connect(),
        throwsA(
          isA<RemoteException>().having((error) => error.code, 'code', 'tls'),
        ),
      );
      final pinned = definition.connection!.trustCertificate(device, 'BAUG');
      final remote = SamsungController(
        pinned,
        credentials,
        () async {},
        false,
        openTransport: (uri, _) async {
          expect(uri.queryParameters, isNot(contains('token')));
          return SamsungTestTransport(reportApps: false)
            ..receive({'event': 'ms.channel.connect', 'data': {}});
        },
      );
      addTearDown(remote.dispose);
      await remote.connect();
      expect(await remote.applications(), isEmpty);
      expect(remote.supports(RemoteCapability.applications), isTrue);
    },
  );

  test(
    'a rejected stored token is cleared for the next pairing attempt',
    () async {
      final credentials = SamsungTestCredentials()
        ..saved = '{"pin":"AQID","token":"old"}';
      final device = SamsungProvider(credentials: credentials)
          .manualDeviceFactory(
            address: '192.168.1.42',
            name: '',
            legacy: false,
            allowInsecurePointer: false,
            certificate: 'AQID',
          );
      final remote = SamsungController(
        device,
        credentials,
        () async {},
        false,
        openTransport: (uri, _) async {
          expect(uri.queryParameters['token'], 'old');
          return SamsungTestTransport()
            ..receive({'event': 'ms.channel.unauthorized'});
        },
      );
      addTearDown(remote.dispose);
      await expectLater(
        remote.connect(),
        throwsA(
          isA<RemoteException>().having(
            (error) => error.code,
            'code',
            'pairingDenied',
          ),
        ),
      );
      expect(credentials.saved, isNull);
      expect(remote.state, DeviceConnectionState.disconnected);
    },
  );

  test(
    'identifies Samsung SSDP evidence and rejects a public endpoint',
    () async {
      final identifier = SamsungProvider(credentials: SamsungTestCredentials())
          .definition
          .identifier;
      final service =
          identifier.requirements.targets[DiscoveryProtocol.ssdp]!.single;
      DiscoveryObservation observation(String host, String target) =>
          DiscoveryObservation(
            protocolId: DiscoveryProtocol.ssdp,
            serviceType: service,
            endpoint: Uri(scheme: 'udp', host: host),
            metadata: {
              'st': target,
              'usn': 'uuid:abcdef01-2345-6789-abcd-ef0123456789',
            },
          );
      final match = await identifier.identify(
        observation('192.168.1.42', service),
        DiscoveryCancellation(),
      );
      expect(
        match?.profile.providerId,
        ProviderIdentity.samsungTizen.storageId,
      );
      expect(match?.profile.device.endpoints.single.port, 8002);
      expect(
        await identifier.identify(
          observation('8.8.8.8', service),
          DiscoveryCancellation(),
        ),
        isNull,
      );
      expect(
        await identifier.identify(
          observation('192.168.1.42', 'ssdp:all'),
          DiscoveryCancellation(),
        ),
        isNull,
      );
    },
  );
  test(
    'disconnect cancels pending TV approval and closes the session',
    () async {
      final credentials = SamsungTestCredentials();
      final device = SamsungProvider(credentials: credentials)
          .manualDeviceFactory(
            address: '192.168.1.42',
            name: 'Samsung',
            legacy: false,
            allowInsecurePointer: false,
            certificate: 'AQID',
          );
      final transport = SamsungTestTransport();
      final controller = SamsungController(
        device,
        credentials,
        () async {},
        false,
        openTransport: (_, _) async => transport,
      );
      addTearDown(controller.dispose);
      final waiting = controller.connectionStates.firstWhere(
        (state) => state == DeviceConnectionState.pairing,
      );
      final connecting = expectLater(
        controller.connect(),
        throwsA(isA<RemoteException>()),
      );
      await waiting;
      await controller.disconnect();
      await connecting;
      expect(controller.state, DeviceConnectionState.disconnected);
      expect(credentials.saved, isNull);
    },
  );
}
