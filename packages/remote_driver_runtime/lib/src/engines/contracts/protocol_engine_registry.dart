import 'package:remote_core/remote_core.dart';

import 'engine_operation.dart';
import 'network_operation.dart';
import 'protocol_engine.dart';

/// The engines compiled into this runtime, keyed by engine ID.
final class ProtocolEngineRegistry {
  ProtocolEngineRegistry(Iterable<ProtocolEngine> engines)
    : _engines = {for (final engine in engines) engine.id: engine};

  /// Bumped when the generic runtime contract changes incompatibly.
  static const api = 2;

  final Map<String, ProtocolEngine> _engines;

  Set<String> get ids => Set.unmodifiable(_engines.keys);

  /// Every executable operation kind across registered engines.
  Set<String> get kinds => {
    for (final engine in _engines.values) ...engine.kinds,
    ...networkKinds,
  };

  /// Kinds executed by the runtime itself rather than a device session.
  static const networkKinds = {'network.wake-on-lan'};

  ProtocolEngine engine(String id) {
    final engine = _engines[id];
    if (engine == null) {
      throw RemoteException(
        'missingEngine',
        'This runtime has no "$id" protocol engine; update the app.',
      );
    }
    return engine;
  }

  /// Whether this runtime can execute an integration's requirements; the
  /// missing operation kinds are reported rather than silently ignored.
  Set<String> missing(RuntimeRequirement requirement) {
    if (requirement.api > api) {
      return {'runtime.api-${requirement.api}'};
    }
    return requirement.operations.difference(kinds);
  }

  EngineOperation compile(String engineId, OperationMapping mapping) {
    if (networkKinds.contains(mapping.kind)) {
      return NetworkOperation.compile(mapping);
    }
    final engine = this.engine(engineId);
    if (!engine.kinds.contains(mapping.kind)) {
      throw FormatException(
        'Engine "$engineId" cannot execute ${mapping.kind} '
        '(${mapping.operation}).',
      );
    }
    return engine.compile(mapping);
  }
}
