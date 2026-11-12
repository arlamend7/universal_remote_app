import 'package:remote_core/remote_core.dart';

import '../engines/contracts/engine_operation.dart';

/// A mapping together with the engine call it compiled into.
final class CompiledMapping {
  const CompiledMapping(this.mapping, this.operation, {this.profileId});

  final OperationMapping mapping;
  final EngineOperation operation;

  /// The profile whose override supplied this mapping, if any.
  final String? profileId;

  String get kind => operation.kind;
  bool get readOnly => mapping.readOnly;
}
