import 'dart:async';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_roku/src/roku_provider.dart';
import 'package:test/test.dart';

void main() {
  RemoteDevice device(
    Uri endpoint, {
    Set<RemoteCapability> capabilities = const {},
  }) => RemoteDevice(
    id: 'roku',
    name: 'Roku',
    providerId: 'roku.ecp',
    endpoints: [endpoint],
    capabilities: capabilities,
  );
  const provider = RokuProvider();

  test('only a Roku that reported TV power control can be woken', () {
    final endpoint = Uri(scheme: 'http', host: '192.168.1.20', port: 8060);
    expect(provider.canWakeDevice(device(endpoint)), isFalse);
    expect(
      provider.canWakeDevice(
        device(endpoint, capabilities: {RemoteCapability.power}),
      ),
      isTrue,
    );
  });

  test('waking sends the documented PowerOn key', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final calls = <String>[];
    server.listen((request) {
      calls.add('${request.method} ${request.uri}');
      unawaited(request.response.close());
    });
    final endpoint = Uri(scheme: 'http', host: '127.0.0.1', port: server.port);
    await provider.wakeDevice(
      device(endpoint, capabilities: {RemoteCapability.power}),
    );
    expect(calls, ['POST /keypress/PowerOn']);
    await expectLater(
      provider.wakeDevice(device(endpoint)),
      throwsA(isA<RemoteException>()),
    );
  });
}
