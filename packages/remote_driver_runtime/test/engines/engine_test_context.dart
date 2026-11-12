import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';

import '../adapters/lg_webos/support/memory_credentials.dart';

/// Builds a session context and records state transitions and pairing.
final class EngineTestContext {
  EngineTestContext(
    this.device, {
    Map<String, Object?> connection = const {},
    MemoryCredentials? credentials,
  }) : credentials = credentials ?? MemoryCredentials(),
       _connection = connection;

  final RemoteDevice device;
  final MemoryCredentials credentials;
  final Map<String, Object?> _connection;
  final states = <DeviceConnectionState>[];
  Future<bool> Function(String code)? submit;

  EngineSessionContext build(ProtocolEngine engine) => EngineSessionContext(
    device: device,
    credentials: credentials,
    credentialKey: device.id,
    connection: engine.compileConnection(_connection),
    onState: states.add,
    onPairingCode: (value) => submit = value,
  );
}
