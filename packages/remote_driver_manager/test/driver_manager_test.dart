import 'dart:convert';
import 'dart:io';

import 'package:remote_driver_manager/remote_driver_manager.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';
import 'package:test/test.dart';

import 'fixture_driver_repository.dart';

Future<(DriverPackage, DriverPackage)> _releases() async {
  const example = 'drivers/providers/example-tv';
  final path = Directory(example);
  final files = await const LocalDriverSource(enabled: true)
      .files(path.existsSync() ? path : Directory('../../$example'));
  final manifest = jsonDecode(files['manifest.json']!) as Map<String, Object?>;
  return (
    DriverPackage(files),
    DriverPackage({
      ...files,
      'manifest.json': jsonEncode({...manifest, 'version': '1.1.0'}),
    }),
  );
}

Future<DriverPackageStorage> _storage() async {
  final directory = await Directory.systemTemp.createTemp('driver-manager-');
  addTearDown(() => directory.delete(recursive: true));
  return DriverPackageStorage(directory);
}

void main() {
  test(
    'retains the exact catalog envelope and ETag for offline validation',
    () async {
      final storage = await _storage();
      expect(await storage.readCatalog(), isNull);
      const catalog = CachedDriverCatalog(
        '{"signed":"fixture"}',
        etag: '"example"',
      );
      await storage.writeCatalog(catalog);
      final cached = await DriverPackageStorage(storage.directory)
          .readCatalog();
      expect(cached?.envelope, catalog.envelope);
      expect(cached?.etag, catalog.etag);
    },
  );

  test(
    'starts offline, installs once, and reloads enabled and rollback state',
    () async {
      final storage = await _storage();
      final (first, next) = await _releases();
      final source = FixtureDriverRepository([first, next]);
      final manager = DriverManager(storage, source);
      await manager.initialize();
      expect(source.requests, 0);
      final id = first.identity.id;
      await Future.wait([
        manager.install(first.identity),
        manager.install(first.identity),
      ]);
      expect(source.requests, 1);
      expect(
        manager.active(id)?.manifest.identity.version,
        first.identity.version,
      );
      await manager.install(next.identity);
      await manager.setEnabled(id, false);
      expect(manager.active(id), isNull);

      final offline = FixtureDriverRepository([]);
      final restarted = DriverManager(storage, offline);
      await restarted.initialize();
      expect(restarted.active(id), isNull);
      expect(restarted.inventory[id]?.active, next.identity.version);
      await restarted.rollback(id);
      await restarted.setEnabled(id, true);
      expect(
        restarted.active(id)?.manifest.identity.version,
        first.identity.version,
      );
      expect(offline.requests, 0);
    },
  );

  test(
    'uncommitted files remain inactive and a corrupted update rolls back',
    () async {
      final storage = await _storage();
      final (first, next) = await _releases();
      final source = FixtureDriverRepository([first, next]);
      final id = first.identity.id;
      final manager = DriverManager(storage, source);
      await manager.initialize();
      await manager.install(first.identity);
      // Simulate interruption after promoting package bytes but before inventory commit.
      await storage.prepare(next);
      final restarted = DriverManager(storage, source);
      await restarted.initialize();
      expect(
        restarted.active(id)?.manifest.identity.version,
        first.identity.version,
      );
      await restarted.install(next.identity);
      expect(source.requests, 1);
      final corrupt = storage.directory
          .listSync()
          .whereType<File>()
          .singleWhere((file) => file.path.endsWith('-1.1.0.json'));
      await corrupt.writeAsString('{bad json');
      final recovered = DriverManager(storage, source);
      await recovered.initialize();
      expect(
        recovered.active(id)?.manifest.identity.version,
        first.identity.version,
      );
      expect(recovered.inventory[id]?.previous, isNull);
      await recovered.install(next.identity);
      expect(source.requests, 2);
    },
  );
}
