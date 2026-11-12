import '../functions/integration_json.dart';
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
  }) : parameters = Map.unmodifiable(parameters) {
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
    if (kind is! String) {
      throw FormatException('Missing engine operation kind: $operation.');
    }
    return OperationMapping(
      operation: operation,
      kind: kind,
      parameters: {...json}..remove('kind'),
    );
  }

  final String operation;
  final String kind;
  final Map<String, Object?> parameters;

  /// The engine namespace, such as `ssap` in `ssap.request`.
  String get engine => kind.split('.').first;

  Map<String, Object?> toJson() => {'kind': kind, ...parameters};
}
