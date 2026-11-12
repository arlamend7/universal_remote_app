import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';
import 'package:remote_driver_runtime/remote_v2.dart';
import 'package:test/test.dart';

import '../engine_test_context.dart';
import 'support/paired_android_tv.dart';

Future<int> _closedPort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

Matcher _failsWith(String code) =>
    throwsA(isA<RemoteException>().having((e) => e.code, 'code', code));

void main() {
  test('a lost session reconnects with the stored pairing', () async {
    final tv = await pairedAndroidTv();
    final states = <DeviceConnectionState>[];
    tv.remote.connectionStates.listen(states.add);
    await tv.remote.connect();
    states.clear();
    tv.server.dropConnections();
    await tv.remote.connectionStates
        .firstWhere((state) => state == DeviceConnectionState.connected)
        .timeout(const Duration(seconds: 5));
    expect(states, contains(DeviceConnectionState.reconnecting));
    expect(states, isNot(contains(DeviceConnectionState.pairing)));
    expect(states.last, DeviceConnectionState.connected);
    tv.recorder.drain();
    await tv.remote.press(NavigationKey.enter);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(tv.recorder.drain().last, {
      'remoteV2': {
        '10': {'1': 23, '2': 3},
      },
    });
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('a user disconnect does not reconnect', () async {
    final tv = await pairedAndroidTv();
    await tv.remote.connect();
    await tv.remote.disconnect();
    tv.server.dropConnections();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(tv.remote.state, DeviceConnectionState.disconnected);
  });

  group('connection failures are typed for wake-and-retry', () {
    Future<EngineTestContext> context({required bool paired}) async {
      final context = EngineTestContext(
        RemoteDevice(
          id: 'android-tv-off',
          name: 'TV',
          providerId: 'android.tv',
          endpoints: [Uri(scheme: 'tls', host: '127.0.0.1', port: 6466)],
        ),
        connection: const {'operatingSystem': 'Android TV'},
      );
      if (paired) {
        final client = await ClientIdentity.generate();
        await context.credentials.write(
          'android-tv-off',
          PairedIdentity(client, 'pinned').encode(),
        );
      }
      return context;
    }

    test('a refused remote port', () async {
      final engine = RemoteV2Engine(portOverride: await _closedPort());
      final paired = await context(paired: true);
      await expectLater(
        engine.open(paired.build(engine)),
        _failsWith('connectionRefused'),
      );
    });

    test('a refused pairing port', () async {
      final engine = RemoteV2Engine(
        portOverride: await _closedPort(),
        pairingPortOverride: await _closedPort(),
      );
      final unpaired = await context(paired: false);
      await expectLater(
        engine.open(unpaired.build(engine)),
        _failsWith('connectionRefused'),
      );
      expect(await unpaired.credentials.read('android-tv-off'), isNull);
    });
  });
}
