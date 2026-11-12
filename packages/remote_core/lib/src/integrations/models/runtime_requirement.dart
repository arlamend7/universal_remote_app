import '../functions/integration_json.dart';

/// The runtime API level and engine operations an integration needs.
final class RuntimeRequirement {
  RuntimeRequirement({required this.api, required Iterable<String> operations})
    : operations = Set.unmodifiable(operations) {
    if (api < 1 ||
        this.operations.isEmpty ||
        !this.operations.every(IntegrationJson.isIdentifier)) {
      throw const FormatException('Invalid runtime requirement.');
    }
  }

  factory RuntimeRequirement.fromJson(Object? value) {
    final json = IntegrationJson.object(value, 'requiredRuntime');
    IntegrationJson.keys(
      json,
      const {'api', 'operations'},
      required: const {'api', 'operations'},
    );
    return RuntimeRequirement(
      api: IntegrationJson.integer(json, 'api', minimum: 1, maximum: 999),
      operations: IntegrationJson.labels(json, 'operations'),
    );
  }

  final int api;

  /// Engine operation kinds such as `ssap.request` or `remote-v2.key`.
  final Set<String> operations;

  Map<String, Object?> toJson() => {
    'api': api,
    'operations': operations.toList()..sort(),
  };
}
