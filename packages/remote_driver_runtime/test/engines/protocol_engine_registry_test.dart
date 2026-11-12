import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';
import 'package:test/test.dart';

void main() {
  final registry = ProtocolEngineRegistry([
    SsapEngine(),
    RemoteV2Engine(),
    SamsungChannelEngine(),
    RokuEcpEngine(),
    JsonWebSocketEngine(),
  ]);

  test('reports missing engines and operations explicitly', () {
    expect(
      () => registry.engine('teletext'),
      throwsA(
        isA<RemoteException>().having((e) => e.code, 'code', 'missingEngine'),
      ),
    );
    expect(
      registry.missing(
        RuntimeRequirement(
          api: 2,
          operations: {'ssap.request', 'ssap.teleport'},
        ),
      ),
      {'ssap.teleport'},
    );
    expect(
      registry.missing(
        RuntimeRequirement(api: 99, operations: {'ssap.request'}),
      ),
      {'runtime.api-99'},
    );
  });

  test('an engine cannot execute another engine kind', () {
    expect(
      () => registry.compile(
        'ssap',
        OperationMapping(
          operation: 'volume-up',
          kind: 'remote-v2.key',
          parameters: const {'code': 24},
        ),
      ),
      throwsFormatException,
    );
  });

  test('Remote v2 keys must be Android KeyEvent codes', () {
    OperationMapping key(Object code) => OperationMapping(
      operation: 'volume-up',
      kind: 'remote-v2.key',
      parameters: {'code': code},
    );
    expect(registry.compile('android-remote-v2', key(24)).describe(), {
      'code': 24,
    });
    for (final code in [-1, 320, '24', 2.5]) {
      expect(
        () => registry.compile('android-remote-v2', key(code)),
        throwsFormatException,
      );
    }
  });

  test('wake-on-LAN is a runtime operation with a bounded broadcast', () {
    final wake = registry.compile(
      'ssap',
      OperationMapping(operation: 'wake', kind: 'network.wake-on-lan'),
    );
    expect(wake, isA<NetworkOperation>());
    expect(
      () => registry.compile(
        'ssap',
        OperationMapping(
          operation: 'wake',
          kind: 'network.wake-on-lan',
          parameters: const {'broadcast': 'evil.example'},
        ),
      ),
      throwsFormatException,
    );
  });
}
