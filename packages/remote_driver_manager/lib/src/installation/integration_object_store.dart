import 'dart:io';
import 'dart:typed_data';

import 'atomic_json_file.dart';
import 'integration_package.dart';
import 'verified_object.dart';

/// Content-addressed package storage: `objects/<sha256>/driver.zip` plus its
/// verification record. Objects are written once and never modified.
final class IntegrationObjectStore {
  const IntegrationObjectStore(this.root);

  final Directory root;

  /// Matches the catalog's package size limit.
  static const maximumBytes = 4 * 1024 * 1024;

  Directory get _objects => Directory('${root.path}/objects');

  Future<bool> contains(String sha256) => File(_zip(sha256)).exists();

  /// Re-hashes the stored bytes so on-disk corruption is never executed.
  Future<(IntegrationPackage, VerifiedObject)?> read(String sha256) async {
    _require(sha256);
    final zip = File(_zip(sha256));
    if (!await zip.exists()) {
      return null;
    }
    final json = await AtomicJsonFile(File(_record(sha256))).read();
    if (json == null) {
      return null;
    }
    final record = VerifiedObject.fromJson(json);
    if (await zip.length() > maximumBytes) {
      throw const FormatException('Stored integration object is too large.');
    }
    final package = IntegrationPackage.read(await zip.readAsBytes());
    if (package.sha256 != sha256 ||
        record.sha256 != sha256 ||
        package.identity != record.identity) {
      throw const FormatException('Stored integration object is corrupt.');
    }
    return (package, record);
  }

  /// Writes a verified package atomically; an existing object is kept.
  Future<void> write(IntegrationPackage package, VerifiedObject record) async {
    if (package.sha256 != record.sha256 ||
        package.identity != record.identity) {
      throw const FormatException('Verification record does not match.');
    }
    if (await _intact(package.sha256)) {
      return;
    }
    await _objects.create(recursive: true);
    final stage = await root.createTemp('staging-');
    try {
      await _stage(stage, package.bytes, record);
      await _replace(stage, Directory('${_objects.path}/${package.sha256}'));
    } finally {
      if (await stage.exists()) {
        await stage.delete(recursive: true);
      }
    }
  }

  Future<Set<String>> hashes() async {
    if (!await _objects.exists()) {
      return const {};
    }
    return {
      await for (final entry in _objects.list())
        if (entry is Directory &&
            VerifiedObject.isHash(
              entry.uri.pathSegments.reversed.skip(1).first,
            ))
          entry.uri.pathSegments.reversed.skip(1).first,
    };
  }

  Future<void> delete(String sha256) async {
    _require(sha256);
    final directory = Directory('${_objects.path}/$sha256');
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<bool> _intact(String sha256) async {
    try {
      return await read(sha256) != null;
    } on FormatException {
      return false;
    }
  }

  static Future<void> _stage(
    Directory stage,
    Uint8List bytes,
    VerifiedObject record,
  ) async {
    await File('${stage.path}/driver.zip').writeAsBytes(bytes, flush: true);
    await AtomicJsonFile(File('${stage.path}/record.json'))
        .write(record.toJson());
  }

  static Future<void> _replace(Directory stage, Directory target) async {
    if (await target.exists()) {
      await target.delete(recursive: true);
    }
    await stage.rename(target.path);
  }

  String _zip(String sha256) => '${_objects.path}/$sha256/driver.zip';
  String _record(String sha256) => '${_objects.path}/$sha256/record.json';

  static void _require(String sha256) {
    if (!VerifiedObject.isHash(sha256)) {
      throw const FormatException('Invalid package object hash.');
    }
  }
}
