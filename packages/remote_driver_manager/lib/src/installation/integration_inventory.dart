import 'dart:io';

import 'atomic_json_file.dart';
import 'installed_integration.dart';

/// `inventory.json` (schema 2): every installed integration and the device
/// assignments that depend on it. Replaced atomically on every change.
final class IntegrationInventory {
  IntegrationInventory(Directory root)
    : _file = AtomicJsonFile(File('${root.path}/inventory.json'));

  static const schema = 2;
  final AtomicJsonFile _file;

  Future<Map<String, InstalledIntegration>> read() async {
    final json = await _file.read();
    if (json == null) {
      return {};
    }
    final records = json['integrations'];
    if (json['schema'] != schema || records is! List<Object?>) {
      throw const FormatException('Invalid integration inventory.');
    }
    final result = <String, InstalledIntegration>{};
    for (final record in records.map(InstalledIntegration.fromJson)) {
      if (result.containsKey(record.integrationId)) {
        throw const FormatException('Duplicate integration installation.');
      }
      result[record.integrationId] = record;
    }
    return result;
  }

  Future<void> write(Iterable<InstalledIntegration> records) => _file.write({
    'schema': schema,
    'integrations': [for (final record in records) record.toJson()],
  });
}
