import 'dart:convert';
import 'dart:io';

import 'package:remote_driver_manager/remote_driver_manager.dart';
import 'package:remote_core/remote_core.dart';
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
    'daily updates persist their window, back off and preserve the old bundle',
    () async {
      final storage = await _storage();
      final (first, next) = await _releases();
      final id = first.identity.id;
      final repository = FixtureDriverRepository([first, next]);
      final manager = DriverManager(storage, repository);
      await manager.initialize();
      final sessionBundle = await manager.install(first.identity);
      var now = DateTime.utc(2026, 1, 1);
      final service = DriverUpdateService(manager, storage, now: () => now);
      final tv = RemoteDevice(
        id: 'fixture',
        name: 'Example TV',
        providerId: first.identity.providerId,
      );
      final catalog = await _updateCatalog(next);
      var requests = 0;
      Future<DriverCatalog> refresh() async {
        requests++;
        return catalog;
      }

      await Future.wait([
        service.check([tv], refresh),
        service.check([tv], refresh),
      ]);
      expect(requests, 1);
      expect(
        manager.active(id)?.manifest.identity.version,
        next.identity.version,
      );
      expect(sessionBundle.manifest.identity.version, first.identity.version);
      await manager.rollback(id);
      final restarted = DriverUpdateService(manager, storage, now: () => now);
      await restarted.check([tv], refresh);
      expect(requests, 1);

      now = now.add(const Duration(hours: 24));
      await expectLater(
        restarted.check([
          tv,
        ], () async => throw const SocketException('offline')),
        throwsA(isA<SocketException>()),
      );
      now = now.add(const Duration(hours: 24));
      await restarted.check([tv], refresh);
      expect(requests, 1);
      now = now.add(const Duration(hours: 24));
      await restarted.check([tv], refresh);
      expect(requests, 2);
      expect(
        manager.active(id)?.manifest.identity.version,
        first.identity.version,
      );
    },
  );

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
    'two televisions can resolve different releases after an offline restart',
    () async {
      final storage = await _storage();
      final (first, next) = await _releases();
      final source = FixtureDriverRepository([first, next]);
      final initial = DriverManager(storage, source);
      await initial.initialize();
      await initial.install(first.identity);
      await initial.install(next.identity);
      final offline = FixtureDriverRepository([]);
      final manager = DriverManager(storage, offline);
      final service = ManagedDriverService(manager, null);
      await service.initialize(ProviderRegistry());
      final pinned = RemoteDevice(
        id: 'pinned',
        name: 'Older TV',
        providerId: first.identity.providerId,
        metadata: {
          'managedDriverId': first.identity.id,
          'managedDriverPinnedVersion': first.identity.version.toString(),
        },
      );
      final other = RemoteDevice(
        id: 'other',
        name: 'New TV',
        providerId: next.identity.providerId,
      );
      final olderBundle = await service.prepare(pinned, cancelled: () => false);
      final newerBundle = await service.prepare(other, cancelled: () => false);
      expect(olderBundle.manifest.identity.version, first.identity.version);
      expect(newerBundle.manifest.identity.version, next.identity.version);
      await manager.rollback(first.identity.id);
      expect(
        (await service.prepare(
          other,
          cancelled: () => false,
        )).manifest.identity.version,
        first.identity.version,
      );
      expect(newerBundle.manifest.identity.version, next.identity.version);
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

Future<DriverCatalog> _updateCatalog(DriverPackage package) {
  final identity = package.identity;
  final data = {
    'schemaVersion': 1,
    'revision': 1,
    'publishedAt': '2026-01-01T00:00:00Z',
    'releases': [
      {
        'manifest': package.bundle.manifest.toJson(),
        'package': 'packages/${identity.id}/${identity.version}/driver.zip',
        'size': 1,
        'sha256': 'a' * 64,
        'signature': 'AQ==',
        'channel': 'stable',
      },
    ],
  };
  return DriverCatalog.verify(
    jsonEncode({
      'keyId': 'fixture',
      'signature': 'AQ==',
      'payload': base64Encode(utf8.encode(jsonEncode(data))),
    }),
    (_, _, _) async => true,
  );
}
