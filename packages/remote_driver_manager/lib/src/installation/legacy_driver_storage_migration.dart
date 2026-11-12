import 'dart:io';

import '../catalog/catalog_integration.dart';
import 'atomic_json_file.dart';
import 'update_schedule.dart';

/// Moves the version-based driver store to the content-addressed layout.
///
/// Version-based package files cannot be re-verified as signed bytes, and
/// their bindings could only repeat compiled defaults, so they are removed
/// rather than converted. The enabled state of each retired family and the
/// update schedule are carried forward.
final class LegacyDriverStorageMigration {
  LegacyDriverStorageMigration({required this.legacyRoot, required this.root})
    : _families = AtomicJsonFile(File('${root.path}/legacy-families.json'));

  final Directory legacyRoot;
  final Directory root;
  final AtomicJsonFile _families;
  static final _package = RegExp(r'^driver-\d+-[a-z0-9._-]+-[0-9.]+\.json$');

  /// Idempotent; returns true when legacy files were found and migrated.
  Future<bool> migrate() async {
    final inventory = File('${legacyRoot.path}/inventory.json');
    final files = await _legacyFiles();
    if (files.isEmpty) {
      return false;
    }
    final legacy = await _readLegacyInventory(inventory);
    await _families.write({
      'families': {
        ...?(await _families.read())?['families'] as Map<String, Object?>?,
        ...legacy,
      },
    });
    await _carrySchedule();
    for (final file in files) {
      await file.delete();
    }
    return true;
  }

  /// Whether the user had disabled a family this integration replaces.
  Future<bool> replacesDisabledFamily(CatalogIntegration entry) async {
    final families = (await _families.read())?['families'];
    if (families is! Map<String, Object?>) {
      return false;
    }
    return entry.replaces.any(
      (family) => (families[family] as Map?)?['enabled'] == false,
    );
  }

  Future<List<File>> _legacyFiles() async {
    if (!await legacyRoot.exists()) {
      return const [];
    }
    const names = {'inventory.json', 'catalog.json', 'updates.json'};
    return [
      await for (final entry in legacyRoot.list())
        if (entry is File &&
            (names.contains(entry.uri.pathSegments.last) ||
                _package.hasMatch(entry.uri.pathSegments.last)))
          entry,
    ];
  }

  static Future<Map<String, Object?>> _readLegacyInventory(File file) async {
    final Map<String, Object?>? json;
    try {
      json = await AtomicJsonFile(file).read();
    } on FormatException {
      return const {};
    }
    final records = json?['installations'];
    if (records is! List<Object?>) {
      return const {};
    }
    return {
      for (final record in records.whereType<Map<String, Object?>>())
        if (record['id'] case final String id)
          id: {'enabled': record['enabled'] != false},
    };
  }

  Future<void> _carrySchedule() async {
    final schedule = UpdateSchedule(root);
    if (await schedule.nextCheck() != null) {
      return;
    }
    final legacy = await AtomicJsonFile(File('${legacyRoot.path}/updates.json'))
        .read()
        .catchError((Object _) => null);
    final next = DateTime.tryParse('${legacy?['nextUpdate']}');
    if (next != null) {
      await schedule.schedule(next);
    }
  }
}
