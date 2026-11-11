import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:remote_core/remote_core.dart';

import 'support/lg_fixture_api.dart';

import 'package:remote_network/remote_network.dart';
import 'package:test/test.dart';

import 'support/fake_transport.dart';
import 'support/memory_credentials.dart';
import 'support/standard_responses.dart';
import 'support/test_device.dart';

void main() {
  test(
    'a failed TV handshake does not read protected pairing credentials',
    () async {
      final credentials = MemoryCredentials();
      final device = LgDeviceController(
        device: testDevice(),
        credentials: credentials,
        options: const LgConnectionOptions(allowInsecure: true),
        connector: (_) async =>
            throw const HandshakeException('CERTIFICATE_VERIFY_FAILED'),
      );
      await expectLater(
        device.connect(),
        throwsA(
          isA<RemoteException>().having((error) => error.code, 'code', 'tls'),
        ),
      );
      expect(credentials.reads, 0);
      await device.dispose();
    },
  );

  test(
    'registration waits for registered event and requests prompt permissions',
    () async {
      final transport = FakeTransport();
      final client = SsapClient(transport);
      transport.respond = (request) {
        transport.reply(request, {'pairingType': 'PROMPT'});
        scheduleMicrotask(
          () => transport.reply(request, {
            'client-key': 'private',
          }, type: 'registered'),
        );
      };
      try {
        expect(await client.register(), 'private');
        final payload =
            transport.sent.single['payload'] as Map<String, dynamic>;
        expect(payload['pairingType'], 'PROMPT');
        expect(payload.containsKey('client-key'), isFalse);
        final manifest = payload['manifest'] as Map<String, dynamic>;
        expect(manifest.containsKey('signatures'), isFalse);
        expect(manifest['permissions'], contains('CONTROL_AUDIO'));
      } finally {
        await client.close();
      }
    },
  );
  test(
    'saved key reused; pairing rejection is typed without leaking payload',
    () async {
      final transport = FakeTransport();
      final client = SsapClient(transport);
      transport.respond = (request) =>
          transport.reject(request, '403 rejected secret-token');
      try {
        await expectLater(
          client.register(clientKey: 'saved'),
          throwsA(
            isA<RemoteException>()
                .having((e) => e.code, 'code', 'pairingRejected')
                .having(
                  (e) => e.message,
                  'message',
                  isNot(contains('secret-token')),
                ),
          ),
        );
        expect(
          (transport.sent.single['payload']
              as Map<String, dynamic>)['client-key'],
          'saved',
        );
      } finally {
        await client.close();
      }
    },
  );
  test('concurrent request IDs correlate out-of-order responses', () async {
    final transport = FakeTransport();
    final client = SsapClient(transport);
    try {
      final one = client.request('audio/one');
      final two = client.request('audio/two');
      expect(transport.sent[0]['id'], isNot(transport.sent[1]['id']));
      transport.reply(transport.sent[1], {'value': 2});
      transport.reply(transport.sent[0], {'value': 1});
      expect((await one)['value'], 1);
      expect((await two)['value'], 2);
    } finally {
      await client.close();
    }
  });
  test('commands and registration have bounded timeouts', () async {
    final client = SsapClient(
      FakeTransport(),
      requestTimeout: const Duration(milliseconds: 15),
    );
    try {
      await expectLater(
        client.request('audio/getVolume'),
        throwsA(
          isA<RemoteException>().having((e) => e.code, 'code', 'timeout'),
        ),
      );
      await expectLater(
        client.register(timeout: const Duration(milliseconds: 15)),
        throwsA(
          isA<RemoteException>().having(
            (e) => e.code,
            'code',
            'pairingTimeout',
          ),
        ),
      );
    } finally {
      await client.close();
    }
  });
  test('error response fails only matching request', () async {
    final transport = FakeTransport();
    final client = SsapClient(transport);
    try {
      final failed = client.request('bad');
      final good = client.request('good');
      final assertion = expectLater(
        failed,
        throwsA(
          isA<RemoteException>().having((e) => e.code, 'code', 'unsupported'),
        ),
      );
      transport.reject(transport.sent[0], '404 not found');
      transport.reply(transport.sent[1], {'ok': true});
      await assertion;
      expect((await good)['ok'], true);
    } finally {
      await client.close();
    }
  });
  test('subscriptions continue after first response and unsubscribe on cancellation', () async {
    final transport = FakeTransport();
    final client = SsapClient(transport);
    final values = <Map<String, Object?>>[];
    final subscription = client.subscribe('audio/getVolume').listen(values.add);
    await Future<void>.delayed(Duration.zero);
    final request = transport.sent.single;
    transport.reply(request, {'volume': 1});
    transport.reply(request, {'volume': 2});
    await Future<void>.delayed(Duration.zero);
    expect(values.map((e) => e['volume']), [1, 2]);
    await subscription.cancel();
    expect(transport.sent.last['type'], 'unsubscribe');
    await client.close();
  });
  test(
    'unexpected disconnect and malformed JSON fail pending requests',
    () async {
      for (final malformed in [false, true]) {
        final transport = FakeTransport();
        final client = SsapClient(transport);
        final pending = client.request('audio/getVolume');
        final assertion = expectLater(pending, throwsA(isA<RemoteException>()));
        if (malformed) {
          transport.incoming.add('not json');
        } else {
          await transport.close();
        }
        await assertion;
        await client.close();
      }
    },
  );
  test('oversized SSAP responses terminate the session', () async {
    final transport = FakeTransport();
    final client = SsapClient(transport);
    addTearDown(client.close);
    final pending = client.request('audio/getVolume');
    final assertion = expectLater(
      pending,
      throwsA(
        isA<RemoteException>().having(
          (error) => error.code,
          'code',
          'protocol',
        ),
      ),
    );
    transport.incoming.add(' ' * (2 * 1024 * 1024 + 1));
    await assertion;
    expect(client.isClosed, isTrue);
  });

  test('pointer navigation uses blank-line separators and click for OK', () {
    expect(encodeLgNavigation(NavigationKey.up), 'type:button\nname:UP\n\n');
    expect(
      encodeLgNavigation(NavigationKey.enter),
      'type:button\nname:ENTER\n\n',
    );
    for (final key in NavigationKey.values) {
      expect(encodeLgNavigation(key).endsWith('\n\n'), isTrue);
    }
  });
  test(
    'authenticated software restrictions apply before controls are exposed',
    () async {
      final main = FakeTransport();
      final pointer = FakeTransport();
      standardResponses(main);
      final controller = LgDeviceController(
        device: testDevice(),
        credentials: MemoryCredentials(),
        options: const LgConnectionOptions(allowInsecure: true),
        bindings: DriverBindings(
          const {},
          profileFor: (device) {
            expect(device.softwareInformation?.firmwareVersion, '04.50.56');
            return DriverCompatibility(
              id: 'fixture-firmware',
              version: 1,
              models: const [],
              disabledCapabilities: const [RemoteCapability.absoluteVolume],
            );
          },
        ),
        connector: (uri) async => uri.path == '/pointer' ? pointer : main,
      );
      addTearDown(controller.dispose);
      await controller.connect();
      expect(
        controller.device.metadata['managedDriverProfile'],
        'fixture-firmware',
      );
      expect(controller.supports(RemoteCapability.absoluteVolume), isFalse);
      await expectLater(
        Future<void>.sync(() => controller.setVolume(50)),
        throwsA(isA<RemoteException>()),
      );
      await controller.volumeUp();
      expect(main.sent.last['uri'], 'ssap://audio/volumeUp');
    },
  );

  for (final managed in [false, true]) {
    test(
      'device pairs and sends equivalent SSAP commands (managed: $managed)',
      () async {
        final credentials = MemoryCredentials();
        final main = FakeTransport();
        final pointer = FakeTransport();
        standardResponses(main);
        final owner = LgDeviceController(
          device: testDevice(),
          credentials: credentials,
          options: const LgConnectionOptions(allowInsecure: true),
          bindings: managed ? await _managedLgBindings() : null,
          connector: (uri) async => uri.path == '/pointer' ? pointer : main,
        );
        try {
          await owner.connect();
          expect(owner.state, DeviceConnectionState.connected);
          expect(credentials.values[testDevice().id], 'secret');
          await owner.setVolume(40);
          expect(
            (main.sent.last['payload'] as Map<String, dynamic>)['volume'],
            40,
          );
          await owner.setMuted(true);
          expect(
            (main.sent.last['payload'] as Map<String, dynamic>)['mute'],
            true,
          );
          await owner.volumeUp();
          expect(main.sent.last['uri'], 'ssap://audio/volumeUp');
          await owner.volumeDown();
          expect(main.sent.last['uri'], 'ssap://audio/volumeDown');
          await owner.powerOff();
          expect(main.sent.last['uri'], 'ssap://system/turnOff');
          await owner.press(NavigationKey.home);
          expect(pointer.frames.single, 'type:button\nname:HOME\n\n');
          expect((await owner.applications()).single.id, 'device.actual.app');
          await owner.launchApplication('device.actual.app');
          expect(
            (main.sent.last['payload'] as Map<String, dynamic>)['id'],
            'device.actual.app',
          );
          await owner.selectInput('HDMI_2');
          expect(
            (main.sent.last['payload'] as Map<String, dynamic>)['inputId'],
            'HDMI_2',
          );
          await owner.turnOffScreen();
          expect(
            main.sent.last['uri'],
            'ssap://com.webos.service.tvpower/power/turnOffScreen',
          );
          await owner.turnOnScreen();
          expect(
            main.sent.last['uri'],
            'ssap://com.webos.service.tvpower/power/turnOnScreen',
          );
          expect((await owner.channels()).single.number, '7');
          await owner.selectChannel('channel-7');
          expect(main.sent.last['uri'], 'ssap://tv/openChannel');
          await owner.channelUp();
          expect(main.sent.last['uri'], 'ssap://tv/channelUp');
          await owner.sendMedia(MediaAction.pause);
          expect(main.sent.last['uri'], 'ssap://media.controls/pause');
          await owner.sendText('search');
          expect(
            main.sent.last['uri'],
            'ssap://com.webos.service.ime/insertText',
          );
          await owner.sendEnter();
          expect(
            main.sent.last['uri'],
            'ssap://com.webos.service.ime/sendEnterKey',
          );
          expect((await owner.currentContent()).appId, 'com.webos.app.hdmi2');
          expect(owner.currentInput?.id, 'HDMI_2');
          expect((await owner.watchVolume().first).volume, 30);
          final accessory = (await owner.bluetoothAccessories()).single;
          await owner.toggleBluetoothAccessory(accessory.id);
          expect(
            main.sent.last['uri'],
            'ssap://com.webos.service.btaudiosrc/connect',
          );
          await owner.click();
          expect(pointer.frames.last, 'type:click\n\n');
          expect(owner.device.softwareInformation?.firmwareVersion, '04.50.56');
          expect(
            owner.device.softwareInformation?.operatingSystemVersion,
            isNull,
          );
          expect(owner.canWake, isFalse);
          await expectLater(owner.wake(), throwsA(isA<RemoteException>()));
          expect(
            owner.evidence
                .firstWhere((e) => e.capability == RemoteCapability.power)
                .availability,
            CapabilityAvailability.known,
          );
        } finally {
          await owner.dispose();
        }
      },
    );
  }

  test(
    'absolute volume rejection disables only the absolute command',
    () async {
      final transport = FakeTransport();
      standardResponses(transport);
      final respond = transport.respond!;
      transport.respond = (request) {
        if (request['uri'] == 'ssap://audio/setVolume') {
          transport.reject(request, '403 denied');
          return;
        }
        respond(request);
      };
      final controller = LgDeviceController(
        device: testDevice(),
        credentials: MemoryCredentials(),
        options: const LgConnectionOptions(allowInsecure: true),
        connector: (uri) async =>
            uri.path == '/pointer' ? FakeTransport() : transport,
      );
      addTearDown(controller.dispose);
      await controller.connect();
      final changed = controller.capabilityChanges.first;
      await expectLater(
        controller.setVolume(20),
        throwsA(isA<RemoteException>()),
      );
      await changed;
      expect(controller.supports(RemoteCapability.absoluteVolume), isFalse);
      expect(controller.supports(RemoteCapability.mute), isTrue);
      expect(controller.supports(RemoteCapability.volumeFeedback), isTrue);
      await controller.volumeUp();
    },
  );

  test('unavailable volume reads do not revoke writes and revoked pairing deletes stale key', () async {
    final credentials = MemoryCredentials();
    final main = FakeTransport();
    standardResponses(main, unsupportedVolume: true);
    final controller = LgDeviceController(
      device: testDevice(),
      credentials: credentials,
      options: const LgConnectionOptions(allowInsecure: true),
      connector: (uri) async => uri.path == '/pointer' ? FakeTransport() : main,
    );
    await controller.connect();
    expect(controller.supports(RemoteCapability.volume), isTrue);
    expect(
      controller.evidence
          .firstWhere((item) => item.capability == RemoteCapability.volume)
          .availability,
      CapabilityAvailability.known,
    );
    await controller.volumeUp();
    expect(main.sent.last['uri'], 'ssap://audio/volumeUp');
    await controller.dispose();
    final rejected = FakeTransport();
    // Assign separately to avoid a self-reference in the initializer.
    rejected.respond = (request) => rejected.reject(request, '403 revoked');
    final revoked = LgDeviceController(
      device: testDevice(),
      credentials: credentials,
      options: const LgConnectionOptions(allowInsecure: true),
      connector: (_) async => rejected,
    );
    await expectLater(
      revoked.connect(),
      throwsA(
        isA<RemoteException>().having((e) => e.code, 'code', 'revokedKey'),
      ),
    );
    expect(credentials.values, isEmpty);
    await revoked.dispose();
  });
  test(
    'disconnect cancels pending pairing, and reconnection reuses stored key',
    () async {
      final credentials = MemoryCredentials();
      final sessions = <FakeTransport>[];
      final controller = LgDeviceController(
        device: testDevice(),
        credentials: credentials,
        options: const LgConnectionOptions(allowInsecure: true),
        connector: (uri) async {
          if (uri.path == '/pointer') return FakeTransport();
          final socket = FakeTransport();
          standardResponses(socket);
          sessions.add(socket);
          return socket;
        },
      );
      await controller.connect();
      await controller.disconnect();
      await controller.connect();
      expect(
        (sessions.last.sent.first['payload']
            as Map<String, dynamic>)['client-key'],
        'secret',
      );
      await controller.dispose();
      final hanging = LgDeviceController(
        device: testDevice(),
        credentials: MemoryCredentials(),
        options: const LgConnectionOptions(allowInsecure: true),
        connector: (_) async => FakeTransport(),
      );
      final pairing = hanging.connect();
      final assertion = expectLater(pairing, throwsA(isA<RemoteException>()));
      await Future<void>.delayed(Duration.zero);
      await hanging.disconnect();
      await assertion;
      await hanging.dispose();
    },
  );
  test('secure default and manual identities are independent of IP', () {
    final provider = LgWebOsProvider(credentials: MemoryCredentials());
    final first = provider.manualDevice('192.168.1.20', profileId: 'local-id');
    final moved = provider.manualDevice('192.168.1.21', profileId: 'local-id');
    expect(first.id, moved.id);
    expect(first.endpoints.single.scheme, 'wss');
    expect(first.stableIdentity, isFalse);
  });
  test(
    'SSAP registration and volume work through a real local WebSocket server',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final sockets = <WebSocket>[];
      final listener = server.listen((request) async {
        // Released in finally.
        // ignore: close_sinks
        final socket = await WebSocketTransformer.upgrade(request);
        sockets.add(socket);
        socket.listen((Object? frame) {
          final request = jsonDecode(frame as String) as Map<String, dynamic>;
          socket.add(
            jsonEncode({
              'id': request['id'],
              'type': request['type'] == 'register' ? 'registered' : 'response',
              'payload': request['type'] == 'register'
                  ? {'client-key': 'local-test-key'}
                  : {'volume': 17, 'muted': false},
            }),
          );
        });
      });
      SsapClient? client;
      try {
        client = SsapClient(
          await IoWebSocketTransport.connect(
            Uri.parse('ws://127.0.0.1:${server.port}'),
          ),
        );
        expect(await client.register(), 'local-test-key');
        expect((await client.request('audio/getVolume'))['volume'], 17);
      } finally {
        await client?.close();
        for (final socket in sockets) {
          await socket.close();
        }
        await listener.cancel();
        await server.close(force: true);
      }
    },
  );
}

Future<DriverBindings> _managedLgBindings() async {
  const path = 'drivers/providers/lg-webos/1.1.0/bindings.json';
  final rootFile = File(path);
  final file = await rootFile.exists() ? rootFile : File('../../$path');
  final values = jsonDecode(await file.readAsString()) as Map<String, Object?>;
  return DriverBindings(values.cast<String, String>());
}
