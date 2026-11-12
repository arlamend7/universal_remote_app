import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import '../../samsung/connection/open_samsung_transport.dart';
import '../common/engine_parameters.dart';
import '../contracts/engine_operation.dart';
import '../contracts/engine_session.dart';
import '../contracts/engine_session_context.dart';
import '../contracts/protocol_engine.dart';
import 'samsung_channel_engine_session.dart';
import 'samsung_channel_kinds.dart';
import 'samsung_channel_operation.dart';

/// Samsung's secure remote-control channel: a certificate-pinned WebSocket,
/// on-screen authorization and an issued token. Keys are validated tokens.
final class SamsungChannelEngine implements ProtocolEngine {
  SamsungChannelEngine({
    Future<TextTransport> Function(Uri endpoint, String pin)? openTransport,
  }) : _openTransport = openTransport ?? openSamsungTransport;

  final Future<TextTransport> Function(Uri, String) _openTransport;
  static final _key = RegExp(r'^KEY_[A-Z0-9_]{1,32}$');

  @override
  String get id => 'samsung-channel';

  @override
  Set<String> get kinds => SamsungChannelKinds.all;

  @override
  EngineOperation compile(OperationMapping mapping) {
    final values = EngineParameters(mapping.kind, mapping.parameters);
    if (mapping.kind != SamsungChannelKinds.key) {
      values.only(const {});
      return SamsungChannelOperation(mapping.kind, const {});
    }
    values.only(const {'key'}, required: const {'key'});
    return SamsungChannelOperation(mapping.kind, {
      'key': values.string('key', _key),
    });
  }

  @override
  Map<String, Object?> compileConnection(Map<String, Object?> json) {
    IntegrationJson.keys(json, const {'clientName', 'authorizeTimeoutMs'});
    return {
      'clientName': json['clientName'] == null
          ? 'Universal Remote'
          : IntegrationJson.label(json, 'clientName'),
      'authorizeTimeoutMs': IntegrationJson.integer(
        {'value': json['authorizeTimeoutMs'] ?? 35000},
        'value',
        minimum: 5000,
        maximum: 120000,
      ),
    };
  }

  @override
  Future<EngineSession> open(EngineSessionContext context) =>
      SamsungChannelEngineSession.open(context, _openTransport);
}
