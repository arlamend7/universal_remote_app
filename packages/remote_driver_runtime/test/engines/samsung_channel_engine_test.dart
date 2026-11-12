import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';
import 'package:test/test.dart';

import '../support/samsung_test_transport.dart';
import 'engine_test_context.dart';

void main() {
  RemoteDevice device({String? pin = 'AQID'}) => RemoteDevice(
    id: 'samsung.tizen:uuid:engine',
    name: 'TV',
    providerId: 'samsung.tizen',
    endpoints: [
      Uri.parse(
        'wss://192.168.1.42:8002/api/v2/channels/samsung.remote.control',
      ),
    ],
    metadata: {'trustedCertificateDer': ?pin},
  );

  test('only KEY_ tokens are accepted', () {
    final engine = SamsungChannelEngine();
    OperationMapping key(String value) => OperationMapping(
      operation: 'volume-up',
      kind: 'samsung-channel.key',
      parameters: {'key': value},
    );
    expect(engine.compile(key('KEY_VOLUP')).describe(), {'key': 'KEY_VOLUP'});
    for (final value in ['volup', 'KEY_', 'KEY_VOL UP', 'KEY_${'A' * 40}']) {
      expect(() => engine.compile(key(value)), throwsFormatException);
    }
  });

  test('authorizes, stores the issued token and sends keys', () async {
    final transports = <SamsungTestTransport>[];
    final requests = <Uri>[];
    final engine = SamsungChannelEngine(
      openTransport: (uri, pin) async {
        requests.add(uri);
        final transport = SamsungTestTransport()
          ..receive({'event': 'ms.remote.touchEnable'})
          ..receive({
            'event': 'ms.channel.connect',
            'data': {'token': '123456'},
          });
        transports.add(transport);
        return transport;
      },
    );
    final context = EngineTestContext(device());
    final session = await engine.open(context.build(engine));
    addTearDown(session.close);
    expect(context.states, [DeviceConnectionState.pairing]);
    expect(requests.single.queryParameters.containsKey('token'), isFalse);
    expect(context.credentials.values['samsung.tizen:uuid:engine'], isNotNull);
    await session.execute(
      engine.compile(
        OperationMapping(
          operation: 'volume-up',
          kind: 'samsung-channel.key',
          parameters: const {'key': 'KEY_VOLUP'},
        ),
      ),
      const {},
    );
    expect(
      transports.single.sent.last['params'],
      containsPair('DataOfCmd', 'KEY_VOLUP'),
    );
    final apps = await session.execute(
      engine.compile(
        OperationMapping(
          operation: 'list-applications',
          kind: 'samsung-channel.applications',
        ),
      ),
      const {},
    );
    expect((apps! as List<DeviceApplication>).single.id, '123');
    expect(session.facts['applications.reported'], 'true');
    await expectLater(
      session.execute(
        engine.compile(
          OperationMapping(
            operation: 'launch-application',
            kind: 'samsung-channel.launch',
          ),
        ),
        const {'target': '../bad'},
      ),
      throwsA(isA<RemoteException>().having((e) => e.code, 'code', 'appId')),
    );
  });

  test('refuses to pair before the certificate is reviewed', () async {
    final engine = SamsungChannelEngine(
      openTransport: (_, _) async => throw StateError('must not connect'),
    );
    await expectLater(
      engine.open(EngineTestContext(device(pin: null)).build(engine)),
      throwsA(isA<RemoteException>().having((e) => e.code, 'code', 'tls')),
    );
  });
}
