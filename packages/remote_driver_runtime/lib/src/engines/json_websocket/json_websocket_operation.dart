import '../contracts/engine_operation.dart';

/// A validated JSON WebSocket request or subscription.
final class JsonWebSocketOperation implements EngineOperation {
  const JsonWebSocketOperation(this.kind, this.parameters);

  @override
  final String kind;
  final Map<String, Object?> parameters;

  Map<String, Object?> get message =>
      parameters['message']! as Map<String, Object?>;
  String get result => parameters['result']! as String;
  String? get event => parameters['event'] as String?;

  @override
  Map<String, Object?> describe() => parameters;
}
