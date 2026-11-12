import '../contracts/engine_operation.dart';

/// A validated Roku ECP call.
final class RokuEcpOperation implements EngineOperation {
  const RokuEcpOperation(this.kind, this.parameters);

  @override
  final String kind;
  final Map<String, Object?> parameters;

  @override
  Map<String, Object?> describe() => parameters;
}
