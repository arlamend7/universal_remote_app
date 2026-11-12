import '../contracts/engine_operation.dart';

/// A validated Samsung secure channel call.
final class SamsungChannelOperation implements EngineOperation {
  const SamsungChannelOperation(this.kind, this.parameters);

  @override
  final String kind;
  final Map<String, Object?> parameters;

  @override
  Map<String, Object?> describe() => parameters;
}
