import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';
import 'package:test/test.dart';

import '../fixture_driver_signer.dart';
import 'support/integration_fixture.dart';
import 'support/static_driver_server.dart';

void main() {
  late Directory directory;
  late FixtureDriverSigner signer;
  late IntegrationFixture fixture;
  late StaticDriverServer server;
  late Directory root;
  var busy = false;
  var now = DateTime.utc(2026, 11, 11, 22);

  IntegrationInstaller installer() =>
      IntegrationInstaller(root, inUse: (_) => busy, now: () => now);

  IntegrationUpdateService updates(IntegrationInstaller installer) {
    final source = DriverHttpSource(server.base, allowLoopbackHttp: true);
    return IntegrationUpdateService(
      catalogs: IntegrationCatalogRepository(
        source,
        root,
        signer.verify,
        now: () => now,
      ),
      packages: HttpIntegrationPackageSource(source),
      verifier: PackageVerifier(signer.verify),
      installer: installer,
      schedule: UpdateSchedule(root),
      now: () => now,
    );
  }

  Future<Map<String, Object?>> publish(
    Uint8List bytes, {
    String lastUpdatedAt = '2026-11-11T21:25:00Z',
  }) async {
    final entry = await fixture.entry(bytes, lastUpdatedAt: lastUpdatedAt);
    server.files[entry['package']! as String] = bytes;
    server.files[IntegrationCatalogRepository.path] = utf8.encode(
      await fixture.envelope([entry]),
    );
    return entry;
  }

  Future<InstalledIntegration> installFirst(IntegrationInstaller target) async {
    await publish(IntegrationFixture.package());
    final service = updates(target);
    final catalog = await service.catalogs.refresh();
    return service.installFromCatalog(catalog.integrations.single, catalog);
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('integrations');
    root = Directory('${directory.path}/installed-drivers');
    signer = FixtureDriverSigner(directory);
    await signer.initialize();
    fixture = IntegrationFixture(signer.sign);
    server = StaticDriverServer();
    await server.start();
    busy = false;
    now = DateTime.utc(2026, 11, 11, 22);
  });

  tearDown(() async {
    await server.close();
    await directory.delete(recursive: true);
  });

  test('installs into an immutable object named by its SHA-256', () async {
    final record = await installFirst(installer());
    final hash = record.current!;
    expect(File('${root.path}/objects/$hash/driver.zip').existsSync(), isTrue);
    expect(record.lastUpdatedAt, DateTime.utc(2026, 11, 11, 21, 25));
    expect(record.installedAt, now);
    final loaded = await installer().load('example.json-websocket');
    expect(loaded!.sha256, hash);
    expect(loaded.package.manifest.identity.providerId, 'example.smarttv');
    expect(loaded.record.source, 'catalog');
  });

  test('an equal hash never downloads the package again', () async {
    await installFirst(installer());
    server.requests.clear();
    final report = await updates(installer()).checkNow();
    expect(report.unchanged, {'example.json-websocket'});
    expect(server.requests, [IntegrationCatalogRepository.path]);
  });

  test(
    'a changed JSON definition installs a new generation in place',
    () async {
      final target = installer();
      final first = (await installFirst(target)).current!;
      fixture.revision = 2;
      final changed = IntegrationFixture.package(
        command: 'volumeUpV2',
        lastUpdatedAt: '2026-11-12T08:00:00Z',
      );
      await publish(changed, lastUpdatedAt: '2026-11-12T08:00:00Z');
      final report = await updates(target).checkNow();
      final second = report.updated['example.json-websocket']!;
      expect(second, isNot(first));
      final record = (await target.installation('example.json-websocket'))!;
      expect((record.current, record.previous), (second, first));
      expect(record.lastUpdatedAt, DateTime.utc(2026, 11, 12, 8));
      final loaded = await target.load('example.json-websocket');
      expect(loaded!.package.files['mappings.json'], contains('volumeUpV2'));
      expect(Directory('${root.path}/objects/$first').existsSync(), isTrue);

      fixture.revision = 3;
      final third = IntegrationFixture.package(
        command: 'volumeUpV3',
        lastUpdatedAt: '2026-11-13T08:00:00Z',
      );
      await publish(third, lastUpdatedAt: '2026-11-13T08:00:00Z');
      await updates(target).checkNow();
      expect(Directory('${root.path}/objects/$first').existsSync(), isFalse);
      expect(Directory('${root.path}/objects/$second').existsSync(), isTrue);
    },
  );

  test('rollback restores the previous generation and is not undone', () async {
    final target = installer();
    final first = (await installFirst(target)).current!;
    fixture.revision = 2;
    await publish(
      IntegrationFixture.package(
        command: 'broken',
        lastUpdatedAt: '2026-11-12T08:00:00Z',
      ),
      lastUpdatedAt: '2026-11-12T08:00:00Z',
    );
    final bad = (await updates(
      target,
    ).checkNow()).updated['example.json-websocket']!;
    final restored = await target.rollback('example.json-websocket');
    expect(restored.current, first);
    expect(restored.rejected, bad);
    expect(restored.lastUpdatedAt, DateTime.utc(2026, 11, 11, 21, 25));
    final report = await updates(target).checkNow();
    expect(report.skipped['example.json-websocket'], contains('rolled back'));
    expect((await target.load('example.json-websocket'))!.sha256, first);
  });

  test(
    'an update never replaces the package under an active session',
    () async {
      final target = installer();
      final first = (await installFirst(target)).current!;
      busy = true;
      fixture.revision = 2;
      await publish(
        IntegrationFixture.package(
          command: 'volumeUpV2',
          lastUpdatedAt: '2026-11-12T08:00:00Z',
        ),
        lastUpdatedAt: '2026-11-12T08:00:00Z',
      );
      final report = await updates(target).checkNow();
      final staged = report.staged['example.json-websocket']!;
      expect((await target.load('example.json-websocket'))!.sha256, first);
      expect(Directory('${root.path}/objects/$staged').existsSync(), isTrue);
      busy = false;
      final activated = await target.activateStaged('example.json-websocket');
      expect((activated!.current, activated.previous), (staged, first));
    },
  );

  test(
    'a corrupt active object falls back to the previous verified one',
    () async {
      final target = installer();
      final first = (await installFirst(target)).current!;
      fixture.revision = 2;
      await publish(
        IntegrationFixture.package(
          command: 'volumeUpV2',
          lastUpdatedAt: '2026-11-12T08:00:00Z',
        ),
        lastUpdatedAt: '2026-11-12T08:00:00Z',
      );
      final second = (await updates(
        target,
      ).checkNow()).updated['example.json-websocket']!;
      File('${root.path}/objects/$second/driver.zip').writeAsStringSync('x');
      final loaded = await target.load('example.json-websocket');
      expect((loaded!.sha256, loaded.recovered), (first, true));
    },
  );

  test('tampered bytes, signatures and metadata are rejected', () async {
    final bytes = IntegrationFixture.package();
    final entry = await fixture.entry(bytes);
    final catalog = IntegrationCatalog.decode({
      'schemaVersion': 2,
      'revision': 1,
      'publishedAt': '2026-11-11T21:30:00Z',
      'integrations': [entry],
    }, 'fixture-key');
    final verifier = PackageVerifier(signer.verify);
    Future<void> verify(Uint8List data, [CatalogIntegration? integration]) =>
        verifier.verify(
          integration ?? catalog.integrations.single,
          data,
          keyId: 'fixture-key',
          catalogRevision: 1,
          source: 'catalog',
          now: now,
        );
    final flipped = Uint8List.fromList(bytes)..[bytes.length - 30] ^= 1;
    await expectLater(verify(flipped), throwsFormatException);
    final mismatched = await fixture.entry(
      bytes,
      lastUpdatedAt: '2026-11-12T00:00:00Z',
    );
    final other = IntegrationCatalog.decode({
      'schemaVersion': 2,
      'revision': 1,
      'publishedAt': '2026-11-11T21:30:00Z',
      'integrations': [mismatched],
    }, 'fixture-key');
    await expectLater(
      verify(bytes, other.integrations.single),
      throwsFormatException,
    );
    final unsigned = IntegrationCatalog.decode({
      'schemaVersion': 2,
      'revision': 1,
      'publishedAt': '2026-11-11T21:30:00Z',
      'integrations': [
        {
          ...entry,
          'signature': base64Encode(await signer.sign([1, 2, 3])),
        },
      ],
    }, 'fixture-key');
    await expectLater(
      verify(bytes, unsigned.integrations.single),
      throwsFormatException,
    );
    await expectLater(
      PackageVerifier(
        signer.verify,
        validate: (_) => throw const FormatException('unsupported engine'),
      ).verify(
        catalog.integrations.single,
        bytes,
        keyId: 'fixture-key',
        catalogRevision: 1,
        source: 'catalog',
        now: now,
      ),
      throwsFormatException,
    );
  });

  test('catalog rollback is refused and the cache works offline', () async {
    await publish(IntegrationFixture.package());
    fixture.revision = 5;
    await publish(IntegrationFixture.package());
    final repository = updates(installer()).catalogs;
    expect((await repository.refresh()).revision, 5);
    fixture.revision = 4;
    await publish(IntegrationFixture.package());
    await expectLater(repository.refresh(), throwsFormatException);
    await server.close();
    server.requests.clear();
    final cached = await repository.cached();
    expect(cached!.revision, 5);
    expect(server.requests, isEmpty);
  });

  test('automatic checks run at most once per day', () async {
    await installFirst(installer());
    final service = updates(installer());
    expect((await service.checkIfDue()).checked, isTrue);
    server.requests.clear();
    now = now.add(const Duration(hours: 23));
    expect((await service.checkIfDue()).checked, isFalse);
    expect(server.requests, isEmpty);
    now = now.add(const Duration(hours: 2));
    expect((await service.checkIfDue()).checked, isTrue);
  });

  test('assignments survive updates unless their profile disappears', () async {
    final target = installer();
    final record = await installFirst(target);
    await target.assign(record.identity, 'lg.webos:uuid:tv', 'bootstrap');
    await target.assign(record.identity, 'tv-2', 'bootstrap');
    await target.unassign('tv-2');
    fixture.revision = 2;
    await publish(
      IntegrationFixture.package(
        command: 'volumeUpV2',
        lastUpdatedAt: '2026-11-12T08:00:00Z',
      ),
      lastUpdatedAt: '2026-11-12T08:00:00Z',
    );
    await updates(target).checkNow();
    final updated = (await target.installation('example.json-websocket'))!;
    expect(updated.assignments.keys, ['lg.webos:uuid:tv']);
    await target.pruneAssignments('example.json-websocket', {'other'});
    expect(
      (await target.installation('example.json-websocket'))!.assignments,
      isEmpty,
    );
  });

  test('legacy versioned storage migrates without losing devices', () async {
    final legacy = Directory('${directory.path}/remote-drivers')..createSync();
    File('${legacy.path}/inventory.json').writeAsStringSync(
      jsonEncode({
        'schema': 1,
        'installations': [
          {'id': 'example-tv', 'active': '1.1.0', 'enabled': false},
          {'id': 'other-tv', 'active': '1.0.0', 'enabled': true},
        ],
      }),
    );
    File('${legacy.path}/driver-10-example-tv-1.1.0.json')
        .writeAsStringSync('{}');
    File(
      '${legacy.path}/updates.json',
    ).writeAsStringSync(jsonEncode({'nextUpdate': '2026-11-12T10:00:00.000Z'}));
    File('${legacy.path}/catalog.json').writeAsStringSync('{}');
    final migration = LegacyDriverStorageMigration(
      legacyRoot: legacy,
      root: Directory('${legacy.path}/installed-drivers'),
    );
    expect(await migration.migrate(), isTrue);
    expect(await migration.migrate(), isFalse);
    expect(
      legacy.listSync().whereType<File>().map(
        (file) => file.uri.pathSegments.last,
      ),
      isEmpty,
    );
    expect(
      await UpdateSchedule(Directory('${legacy.path}/installed-drivers'))
          .nextCheck(),
      DateTime.utc(2026, 11, 12, 10),
    );
    final entry = await fixture.entry(IntegrationFixture.package());
    final catalog = IntegrationCatalog.decode({
      'schemaVersion': 2,
      'revision': 1,
      'publishedAt': '2026-11-11T21:30:00Z',
      'integrations': [entry],
    }, 'fixture-key');
    expect(
      await migration.replacesDisabledFamily(catalog.integrations.single),
      isTrue,
    );

    final metadata = {
      'managedDriverId': 'example-tv',
      'managedDriverVersion': '1.1.0',
      'managedDriverProfile': 'secure-remote',
      'managedDriverProfileVersion': '1',
      'trustedCertificateDer': 'AQID',
      'macAddress': 'AA:BB:CC:DD:EE:FF',
    };
    expect(migrateLegacyDeviceMetadata(metadata, catalog: catalog), {
      'trustedCertificateDer': 'AQID',
      'macAddress': 'AA:BB:CC:DD:EE:FF',
      DeviceMetadataKeys.integrationId: 'example.json-websocket',
    });
    expect(migrateLegacyDeviceMetadata(metadata), {
      'trustedCertificateDer': 'AQID',
      'macAddress': 'AA:BB:CC:DD:EE:FF',
    });
    final untouched = {'trustedCertificateDer': 'AQID'};
    expect(
      identical(migrateLegacyDeviceMetadata(untouched), untouched),
      isTrue,
    );
  });

  test('records reject malformed hashes and provider changes', () {
    expect(
      () => InstalledIntegration.fromJson({
        'integrationId': 'example.json-websocket',
        'providerId': 'example.smarttv',
        'enabled': true,
        'current': '1.0.0',
      }),
      throwsFormatException,
    );
    expect(
      VerifiedObject.isHash(IntegrationPackage.digest(utf8.encode('x'))),
      isTrue,
    );
    expect(RemoteException('x', 'y').code, 'x');
  });
}
