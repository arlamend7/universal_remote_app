import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';
import 'package:test/test.dart';

import '../parity/roku_ecp_parity_server.dart';
import '../parity/support/parity_recorder.dart';
import 'engine_test_context.dart';

void main() {
  late RokuEcpParityServer server;
  late ParityRecorder recorder;
  final engine = RokuEcpEngine();
  const connection = {
    'operatingSystem': 'Roku OS',
    'inputKeys': {'tvinput.hdmi1': 'InputHDMI1'},
  };
  EngineOperation op(String kind, [Map<String, Object?> p = const {}]) =>
      engine.compile(
        OperationMapping(operation: 'volume-up', kind: kind, parameters: p),
      );

  setUp(() async {
    recorder = ParityRecorder();
    server = RokuEcpParityServer(recorder);
    await server.start();
  });
  tearDown(() => server.close());

  RemoteDevice device({String? serial}) => RemoteDevice(
    id: 'roku.ecp:PARITY01',
    name: 'Roku',
    providerId: 'roku.ecp',
    endpoints: [server.endpoint],
    metadata: {'rokuSerial': ?serial},
  );

  test('keys and input keys are limited to documented ECP names', () {
    expect(() => op('roku-ecp.key', {'key': 'Lit_a'}), throwsFormatException);
    expect(
      () => op('roku-ecp.key', {'key': '../launch'}),
      throwsFormatException,
    );
    expect(
      () => engine.compileConnection({
        'inputKeys': {'tvinput.hdmi1': 'PowerOff'},
      }),
      throwsFormatException,
    );
  });

  test('identifies the device and reports declared facts', () async {
    final context = EngineTestContext(device(), connection: connection);
    final session = await engine.open(context.build(engine));
    expect(recorder.drain(), [
      {'ecp': 'GET /query/device-info'},
      {'ecp': 'GET /query/apps'},
      {'ecp': 'GET /query/active-app'},
      {'ecp': 'GET /query/tv-channels'},
    ]);
    expect(session.facts, {
      'device.is-tv': 'true',
      'device.supports-tv-power-control': 'true',
      'catalog.applications': 'true',
      'catalog.inputs': 'true',
      'tuner.channels': 'true',
      'content.reported': 'true',
    });
    expect(session.software?.operatingSystemVersion, '12.5.0');
    expect(session.software?.operatingSystem, 'Roku OS');
    expect(session.reportedDiscoveryIdentity, 'uuid:roku:ecp:PARITY01');
    await session.execute(op('roku-ecp.text'), const {'text': 'ab'});
    await session.execute(op('roku-ecp.select-input'), const {
      'target': 'tvinput.hdmi1',
    });
    final reading = await session.execute(
      op('roku-ecp.read-content'),
      const {},
    ) as ContentReading;
    expect(reading.content.position, const Duration(seconds: 1));
    expect(recorder.drain().take(3), [
      {'ecp': 'POST /keypress/Lit_a'},
      {'ecp': 'POST /keypress/Lit_b'},
      {'ecp': 'POST /keypress/InputHDMI1'},
    ]);
    await expectLater(
      session.execute(op('roku-ecp.launch'), const {'target': '999'}),
      throwsA(isA<RemoteException>()),
    );
  });

  test('refuses an address that now belongs to another Roku', () async {
    final context = EngineTestContext(
      device(serial: 'OTHER'),
      connection: connection,
    );
    await expectLater(
      engine.open(context.build(engine)),
      throwsA(isA<RemoteException>().having((e) => e.code, 'code', 'identity')),
    );
  });
}
