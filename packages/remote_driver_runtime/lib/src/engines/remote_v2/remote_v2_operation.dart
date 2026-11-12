import '../contracts/engine_operation.dart';

/// A validated Remote v2 engine call.
final class RemoteV2Operation implements EngineOperation {
  const RemoteV2Operation(this.kind, this.parameters);

  @override
  final String kind;
  final Map<String, Object?> parameters;

  int get code => parameters['code']! as int;

  @override
  Map<String, Object?> describe() => parameters;
}
