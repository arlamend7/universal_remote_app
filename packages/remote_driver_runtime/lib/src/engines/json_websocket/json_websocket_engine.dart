import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import '../common/engine_parameters.dart';
import '../common/payload_template.dart';
import '../contracts/engine_operation.dart';
import '../contracts/engine_session.dart';
import '../contracts/engine_session_context.dart';
import '../contracts/protocol_engine.dart';
import 'json_websocket_engine_session.dart';
import 'json_websocket_kinds.dart';
import 'json_websocket_operation.dart';

/// A fully declarative engine for TVs that speak plain JSON over TLS
/// WebSockets. Messages are bounded templates; reserved envelope fields
/// (`id`, `code`, `token`) are owned by the engine.
final class JsonWebSocketEngine implements ProtocolEngine {
  JsonWebSocketEngine({TransportConnector? connector})
    : _connector = connector ?? _connect;

  final TransportConnector _connector;
  static const _reserved = {'id', 'code', 'token'};
  static final _event = RegExp(r'^[a-zA-Z0-9_.-]{1,64}$');

  @override
  String get id => 'json-websocket';

  @override
  Set<String> get kinds => JsonWebSocketKinds.all;

  @override
  EngineOperation compile(OperationMapping mapping) {
    JsonWebSocketEngineSession.validateKind(mapping.kind);
    final values = EngineParameters(mapping.kind, mapping.parameters);
    values.only(const {'message', 'result', 'event'}, required: {'message'});
    return JsonWebSocketOperation(mapping.kind, {
      'message': _template(mapping.parameters['message']),
      'result': mapping.parameters['result'] == null
          ? 'none'
          : values.choice('result', JsonWebSocketKinds.results),
      'event': values.optionalString('event', _event),
    });
  }

  @override
  Map<String, Object?> compileConnection(Map<String, Object?> json) {
    IntegrationJson.keys(
      json,
      const {'pairing', 'authentication', 'timeoutMs'},
      required: const {'pairing', 'authentication'},
    );
    return {
      for (final name in const ['pairing', 'authentication'])
        name: {'message': _template(_object(json[name])['message'])},
      'timeoutMs': IntegrationJson.integer(
        {'value': json['timeoutMs'] ?? 5000},
        'value',
        minimum: 500,
        maximum: 60000,
      ),
    };
  }

  @override
  Future<EngineSession> open(EngineSessionContext context) =>
      JsonWebSocketEngineSession.open(context, _connector);

  static Map<String, Object?> _template(Object? value) {
    final template = PayloadTemplate.parse(value, PayloadTemplate.arguments);
    if (template.template.keys.any(_reserved.contains) ||
        template.template.isEmpty) {
      throw const FormatException('Invalid JSON WebSocket message.');
    }
    return template.template;
  }

  static Map<String, Object?> _object(Object? value) =>
      IntegrationJson.object(value, 'json-websocket');

  static Future<TextTransport> _connect(Uri endpoint) =>
      IoWebSocketTransport.connect(endpoint);
}
