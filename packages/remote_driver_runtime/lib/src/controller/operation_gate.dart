import 'package:remote_core/remote_core.dart';

import '../integrations/compiled_mapping.dart';
import '../integrations/integration_definition.dart';
import '../integrations/operation_table.dart';
import '../integrations/resolved_capability.dart';

/// Decides whether a runtime operation may run now and which capability a
/// failure withdraws. An unmapped operation is unsupported; a mapped one
/// whose capability is not usable is unavailable.
final class OperationGate {
  OperationGate(this.definition, this.table, this.resolved);

  final IntegrationDefinition definition;
  final OperationTable table;
  final Map<RemoteCapability, ResolvedCapability> resolved;

  CompiledMapping require(String operation) {
    final mapping = table[operation];
    if (mapping == null) {
      throw const RemoteException(
        'unsupported',
        'This command is not supported by this TV.',
      );
    }
    final capability = gateFor(operation);
    if (capability != null && resolved[capability]?.usable != true) {
      throw RemoteException(
        'unavailable',
        'This control is unavailable on the connected TV (${capability.name}).',
      );
    }
    return mapping;
  }

  bool allows(String operation) {
    try {
      require(operation);
      return true;
    } on RemoteException {
      return false;
    }
  }

  /// The explicit gate, else the declared capability that selected the
  /// operation, else any declared capability listing it.
  RemoteCapability? gateFor(String operation) {
    final explicit = table[operation]?.mapping.gate;
    if (explicit != null) {
      return explicit;
    }
    for (final entry in resolved.entries) {
      if (entry.value.operations.contains(operation)) {
        return entry.key;
      }
    }
    for (final declaration in definition.capabilities) {
      if (declaration.alternatives.any((set) => set.contains(operation))) {
        return declaration.capability;
      }
    }
    return null;
  }

  /// The capability to withdraw after [error], if its declaration says so.
  RemoteCapability? withdraws(String operation, RemoteException error) {
    final mapping = table[operation];
    final capability = gateFor(operation);
    if (mapping == null || mapping.readOnly || capability == null) {
      return null;
    }
    final declaration = definition.capabilities
        .where((candidate) => candidate.capability == capability)
        .firstOrNull;
    return declaration?.disableOn.contains(error.code) == true
        ? capability
        : null;
  }

  /// Validates arguments against the mapping's declared constraints.
  void check(CompiledMapping mapping, Map<String, Object?> arguments) {
    for (final entry in mapping.mapping.constraints.entries) {
      _check(entry.key, arguments[entry.key], entry.value);
    }
  }

  static void _check(String name, Object? value, Map<String, int> bounds) {
    final length = value is String ? value.length : null;
    final number = value is num ? value : null;
    final valid =
        (length == null ||
            (length >= (bounds['minLength'] ?? 0) &&
                length <= (bounds['maxLength'] ?? length))) &&
        (number == null ||
            (number >= (bounds['minimum'] ?? number) &&
                number <= (bounds['maximum'] ?? number)));
    if (!valid) {
      throw ArgumentError.value(value, name, 'Outside the supported range.');
    }
  }
}
