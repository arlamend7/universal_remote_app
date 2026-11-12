import '../../device.dart';
import '../functions/integration_json.dart';
import '../functions/parse_remote_capability.dart';
import '../functions/runtime_operations.dart';

/// One runtime operation bound to a typed engine call (`mappings.json`).
///
/// [kind] names the engine call (for example `ssap.request`); [parameters]
/// are validated by that engine before the integration can be activated.
final class OperationMapping {
  OperationMapping({
    required this.operation,
    required this.kind,
    Map<String, Object?> parameters = const {},
    this.readOnly = false,
    this.gate,
    Map<String, Map<String, int>> constraints = const {},
  }) : parameters = Map.unmodifiable(parameters),
       constraints = Map.unmodifiable(constraints) {
    if (!RuntimeOperations.isMappable(operation)) {
      throw FormatException('Unknown runtime operation: $operation.');
    }
    if (!IntegrationJson.isIdentifier(kind)) {
      throw const FormatException('Invalid engine operation kind.');
    }
  }

  factory OperationMapping.fromJson(String operation, Object? value) {
    final json = IntegrationJson.object(value, operation);
    final kind = json['kind'];
    final readOnly = json['readOnly'] ?? false;
    final gate = json['gate'];
    if (kind is! String || readOnly is! bool) {
      throw FormatException('Invalid engine operation mapping: $operation.');
    }
    return OperationMapping(
      operation: operation,
      kind: kind,
      parameters: {...json}..removeWhere(_generic),
      readOnly: readOnly,
      gate: gate == null ? null : parseRemoteCapability(gate),
      constraints: _constraints(json['constraints']),
    );
  }

  final String operation;
  final String kind;
  final Map<String, Object?> parameters;

  /// A status query: its failures never withdraw a capability.
  final bool readOnly;

  /// The capability that must be usable before this operation runs, when it
  /// is not implied by the capability declarations (for example keys sent
  /// over a secondary channel).
  final RemoteCapability? gate;

  /// Argument bounds checked before sending: `minLength`/`maxLength` for
  /// text, `minimum`/`maximum` for numbers.
  final Map<String, Map<String, int>> constraints;

  static const _genericKeys = {'kind', 'readOnly', 'gate', 'constraints'};
  static const _bounds = {'minLength', 'maxLength', 'minimum', 'maximum'};

  static bool _generic(String key, Object? _) => _genericKeys.contains(key);

  static Map<String, Map<String, int>> _constraints(Object? value) {
    if (value == null) {
      return const {};
    }
    final json = IntegrationJson.object(value, 'constraints');
    return {for (final entry in json.entries) entry.key: _bound(entry.value)};
  }

  static Map<String, int> _bound(Object? value) {
    final json = IntegrationJson.object(value, 'constraint');
    if (!json.keys.every(_bounds.contains) ||
        !json.values.every((bound) => bound is int && bound >= -1000000)) {
      throw const FormatException('Invalid operation argument constraint.');
    }
    return json.cast<String, int>();
  }

  /// The engine namespace, such as `ssap` in `ssap.request`.
  String get engine => kind.split('.').first;

  Map<String, Object?> toJson() => {
    'kind': kind,
    if (readOnly) 'readOnly': true,
    if (gate != null) 'gate': gate!.name,
    if (constraints.isNotEmpty) 'constraints': constraints,
    ...parameters,
  };
}
