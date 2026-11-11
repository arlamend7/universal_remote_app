import 'dart:convert';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';

import 'cached_driver_catalog.dart';
import 'driver_installation.dart';
import 'driver_package.dart';

/// Stores complete packages and commits activation in a separate atomic index.
final class DriverPackageStorage {
  const DriverPackageStorage(this.directory);

  final Directory directory;

  Future<CachedDriverCatalog?> readCatalog() async {
    final file = _catalog;
    if (!await file.exists()) {
      return null;
    }
    return CachedDriverCatalog.fromJson(await _readJson(file));
  }

  Future<void> writeCatalog(CachedDriverCatalog catalog) =>
      _write(_catalog, catalog.toJson());

  Future<Map<String, DriverInstallation>> readInventory() async {
    final file = _inventory;
    if (!await file.exists()) {
      return {};
    }
    final json = await _readJson(file);
    if (json['schema'] != 1 || json['installations'] is! List<Object?>) {
      throw const FormatException('Invalid driver inventory.');
    }
    final records = (json['installations'] as List<Object?>).map(_record);
    final result = <String, DriverInstallation>{};
    for (final record in records) {
      if (result.containsKey(record.id)) {
        throw const FormatException('Duplicate driver installation.');
      }
      result[record.id] = record;
    }
    return result;
  }

  Future<void> writeInventory(Iterable<DriverInstallation> entries) =>
      _write(_inventory, {
        'schema': 1,
        'installations': entries.map((entry) => entry.toJson()).toList(),
      });

  Future<DriverPackage?> read(String id, DriverVersion version) async {
    final file = _file(id, version);
    if (!await file.exists()) {
      return null;
    }
    final json = await _readJson(file);
    if (json.length > DriverBundle.maximumFiles ||
        !json.values.every(_isText)) {
      throw const FormatException('Invalid stored driver package.');
    }
    final package = DriverPackage(json.cast<String, String>());
    if (package.identity.id != id || package.identity.version != version) {
      throw const FormatException('Stored driver identity does not match.');
    }
    return package;
  }

  Future<void> prepare(DriverPackage package) async {
    final identity = package.identity;
    final existing = await _validPackage(identity);
    if (existing != null) {
      if (!_sameFiles(existing.files, package.files)) {
        throw const RemoteException(
          'driverConflict',
          'Driver versions are immutable.',
        );
      }
      return;
    }
    await _write(_file(identity.id, identity.version), package.files);
  }

  Future<DriverPackage?> _validPackage(DriverIdentity identity) async {
    try {
      return await read(identity.id, identity.version);
    } on FormatException {
      return null;
    }
  }

  Future<void> _write(File destination, Map<String, Object?> payload) async {
    final bytes = utf8.encode(jsonEncode(payload));
    if (bytes.length > _maximumStorageBytes) {
      throw const FormatException('Driver storage entry is too large.');
    }
    await directory.create(recursive: true);
    final stage = await directory.createTemp('staging-');
    try {
      final pending = File('${stage.path}/content.json');
      await pending.writeAsBytes(bytes, flush: true);
      await pending.rename(destination.path);
    } finally {
      await stage.delete(recursive: true);
    }
  }

  static Future<Map<String, Object?>> _readJson(File file) async {
    final handle = await file.open();
    try {
      final bytes = await handle.read(_maximumStorageBytes + 1);
      if (bytes.length > _maximumStorageBytes) {
        throw const FormatException('Driver storage entry is too large.');
      }
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map<String, Object?>) {
        throw const FormatException('Invalid driver storage entry.');
      }
      return json;
    } finally {
      await handle.close();
    }
  }

  File get _catalog => File('${directory.path}/catalog.json');

  File get _inventory => File('${directory.path}/inventory.json');

  File _file(String id, DriverVersion version) {
    DriverIdentity(id: id, providerId: id, version: version);
    return File('${directory.path}/driver-${id.length}-$id-$version.json');
  }

  static DriverInstallation _record(Object? value) {
    if (value is! Map<String, Object?>) {
      throw const FormatException('Invalid driver installation record.');
    }
    return DriverInstallation.fromJson(value);
  }

  static bool _sameFiles(Map<String, String> a, Map<String, String> b) =>
      a.length == b.length &&
      a.entries.every((entry) => b[entry.key] == entry.value);

  static bool _isText(Object? value) => value is String;

  // Storage wraps the validated UTF-8 files in JSON, which can expand escapes.
  static const _maximumStorageBytes = 4 * 1024 * 1024;
}
