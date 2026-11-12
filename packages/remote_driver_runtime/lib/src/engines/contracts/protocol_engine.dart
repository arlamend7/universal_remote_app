import 'package:remote_core/remote_core.dart';

import 'engine_operation.dart';
import 'engine_session.dart';
import 'engine_session_context.dart';

/// A compiled, trusted protocol implementation. Engines never choose a
/// provider, integration or compatibility profile; driver data selects them.
abstract interface class ProtocolEngine {
  /// Stable engine ID referenced by `manifest.json#engine`.
  String get id;

  /// The operation kinds this engine can execute, such as `ssap.request`.
  Set<String> get kinds;

  /// Validates one mapping against the engine's typed parameter rules.
  /// Throws [FormatException] for anything outside the safe vocabulary.
  EngineOperation compile(OperationMapping mapping);

  /// Validates and normalizes this engine's `connection.json` section.
  Map<String, Object?> compileConnection(Map<String, Object?> json);

  Future<EngineSession> open(EngineSessionContext context);
}
