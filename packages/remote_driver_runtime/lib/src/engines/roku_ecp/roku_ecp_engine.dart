import 'package:remote_core/remote_core.dart';

import '../../ecp/roku_ecp_client.dart';
import '../common/engine_parameters.dart';
import '../contracts/engine_operation.dart';
import '../contracts/engine_session.dart';
import '../contracts/engine_session_context.dart';
import '../contracts/offline_wake_engine.dart';
import '../contracts/protocol_engine.dart';
import 'roku_ecp_engine_session.dart';
import 'roku_ecp_kinds.dart';
import 'roku_ecp_operation.dart';

/// Roku External Control Protocol over local HTTP (port 8060).
final class RokuEcpEngine implements ProtocolEngine, OfflineWakeEngine {
  RokuEcpEngine({RokuEcpClient Function(Uri endpoint)? client})
    : _client = client ?? RokuEcpClient.new;

  final RokuEcpClient Function(Uri endpoint) _client;
  static final _inputId = RegExp(r'^tvinput\.[a-z0-9]{1,16}$');

  @override
  String get id => 'roku-ecp';

  @override
  Set<String> get kinds => RokuEcpKinds.all;

  @override
  EngineOperation compile(OperationMapping mapping) {
    final values = EngineParameters(mapping.kind, mapping.parameters);
    if (mapping.kind != RokuEcpKinds.key) {
      values.only(const {});
      return RokuEcpOperation(mapping.kind, const {});
    }
    values.only(const {'key'}, required: const {'key'});
    return RokuEcpOperation(mapping.kind, {
      'key': values.choice('key', RokuEcpKinds.keys),
    });
  }

  @override
  Map<String, Object?> compileConnection(Map<String, Object?> json) {
    IntegrationJson.keys(json, const {'inputKeys', 'operatingSystem'});
    final keys = IntegrationJson.object(
      json['inputKeys'] ?? const <String, Object?>{},
      'inputKeys',
    );
    if (keys.length > 16 ||
        !keys.entries.every(
          (entry) =>
              _inputId.hasMatch(entry.key) &&
              RokuEcpKinds.keys.contains(entry.value) &&
              '${entry.value}'.startsWith('Input'),
        )) {
      throw const FormatException('Invalid ECP input keys.');
    }
    return {
      'inputKeys': keys.cast<String, String>(),
      'operatingSystem': IntegrationJson.optionalLabel(json, 'operatingSystem'),
    };
  }

  @override
  Future<EngineSession> open(EngineSessionContext context) {
    final endpoint = context.device.endpoints.singleOrNull;
    if (endpoint == null) {
      throw const RemoteException(
        'setup',
        'Roku requires a local address and its HTTP control port.',
      );
    }
    return RokuEcpEngineSession.open(context, _client(endpoint));
  }

  /// Sends a key in network standby; only documented key names compile.
  @override
  Future<void> wakeOffline(RemoteDevice device, EngineOperation operation) {
    final endpoint = device.endpoints.singleOrNull;
    if (endpoint == null || operation.kind != RokuEcpKinds.key) {
      throw const RemoteException(
        'wakeUnavailable',
        'This device cannot be woken from the network.',
      );
    }
    return _client(endpoint).key(operation.describe()['key']! as String);
  }
}
