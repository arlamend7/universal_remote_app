import '../../contracts/engine_operation.dart';

/// A validated SSAP engine call.
final class SsapOperation implements EngineOperation {
  const SsapOperation(this.kind, this.parameters);

  @override
  final String kind;

  /// Already validated by `SsapOperationCompiler`; read without re-checking.
  final Map<String, Object?> parameters;

  String get uri => parameters['uri']! as String;
  String? string(String key) => parameters[key] as String?;

  Duration? get timeout => switch (parameters['timeoutMs']) {
    final int milliseconds => Duration(milliseconds: milliseconds),
    _ => null,
  };

  @override
  Map<String, Object?> describe() => parameters;
}
