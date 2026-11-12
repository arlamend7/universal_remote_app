import 'compiled_mapping.dart';

/// The effective runtime operation → engine call table for one profile.
final class OperationTable {
  OperationTable(Map<String, CompiledMapping> entries)
    : _entries = Map.unmodifiable(entries);

  final Map<String, CompiledMapping> _entries;

  CompiledMapping? operator [](String operation) => _entries[operation];

  bool has(String operation) => _entries.containsKey(operation);

  Set<String> get operations => _entries.keys.toSet();

  /// The mapping actually selected for each operation, for diagnostics.
  Map<String, Map<String, Object?>> get diagnostics => {
    for (final entry in _entries.entries)
      entry.key: {
        'kind': entry.value.kind,
        ...entry.value.operation.describe(),
        if (entry.value.readOnly) 'readOnly': true,
        if (entry.value.profileId != null) 'profile': entry.value.profileId,
      },
  };
}
