import 'package:remote_core/remote_core.dart';

import '../common/engine_parameters.dart';
import '../contracts/engine_operation.dart';
import '../contracts/engine_session.dart';
import '../contracts/engine_session_context.dart';
import '../contracts/protocol_engine.dart';
import 'remote_v2_engine_session.dart';
import 'remote_v2_kinds.dart';
import 'remote_v2_operation.dart';

/// Android TV Remote v2: certificate pairing, pinned TLS and binary framing.
/// Integrations only choose validated Android `KeyEvent` codes.
final class RemoteV2Engine implements ProtocolEngine {
  RemoteV2Engine({this.portOverride});

  /// Test seam for a loopback TLS endpoint; null uses the declared port.
  final int? portOverride;

  /// Android `KeyEvent` codes are non-negative and below this bound.
  static const maximumKeyCode = 319;

  @override
  String get id => 'android-remote-v2';

  @override
  Set<String> get kinds => RemoteV2Kinds.all;

  @override
  EngineOperation compile(OperationMapping mapping) {
    final values = EngineParameters(mapping.kind, mapping.parameters);
    if (mapping.kind != RemoteV2Kinds.key) {
      values.only(const {});
      return RemoteV2Operation(mapping.kind, const {});
    }
    values.only(const {'code'}, required: const {'code'});
    return RemoteV2Operation(mapping.kind, {
      'code': values.integer('code', minimum: 0, maximum: maximumKeyCode),
    });
  }

  @override
  Map<String, Object?> compileConnection(Map<String, Object?> json) {
    IntegrationJson.keys(json, const {'port', 'operatingSystem'});
    return {
      'port': IntegrationJson.integer(
        {'port': json['port'] ?? 6466},
        'port',
        minimum: 1,
        maximum: 65535,
      ),
      'operatingSystem': IntegrationJson.optionalLabel(json, 'operatingSystem'),
    };
  }

  @override
  Future<EngineSession> open(EngineSessionContext context) =>
      RemoteV2EngineSession.open(context, portOverride: portOverride);
}
