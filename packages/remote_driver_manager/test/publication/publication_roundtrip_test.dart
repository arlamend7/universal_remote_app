import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';
import 'package:remote_driver_runtime/authoring.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';
import 'package:test/test.dart';

import '../installation/support/static_driver_server.dart';
import 'openssl_verifier.dart';

Directory _repository() {
  var directory = Directory.current.absolute;
  while (!Directory('${directory.path}/drivers/providers').existsSync()) {
    directory = directory.parent;
  }
  return directory;
}

Future<void> _run(String executable, List<String> arguments) async {
  final result = await Process.run(executable, arguments);
  if (result.exitCode != 0) {
    throw StateError('$executable failed: ${result.stderr}');
  }
}

void main() {
  test(
    'a published site seeds, installs, updates and rolls back offline-first',
    () async {
      final repository = _repository();
      final temporary = await Directory.systemTemp.createTemp('publication');
      addTearDown(() => temporary.delete(recursive: true));
      final key = '${temporary.path}/key.pem';
      final public = File('${temporary.path}/public.pem');
      await _run('openssl', [
        'genpkey',
        '-algorithm',
        'EC',
        '-pkeyopt',
        'ec_paramgen_curve:P-256',
        '-out',
        key,
      ]);
      await _run('openssl', [
        'pkey',
        '-in',
        key,
        '-pubout',
        '-out',
        public.path,
      ]);
      final source = await Directory('${temporary.path}/lg').create();
      final original = Directory(
        '${repository.path}/drivers/providers/lg-webos/webos-22-plus',
      );
      for (final entry in readDriverSourceFiles(original).entries) {
        File('${source.path}/${entry.key}').writeAsStringSync(entry.value);
      }
      final index = File('${temporary.path}/catalog.json')
        ..writeAsStringSync(
          jsonEncode({
            'schemaVersion': 2,
            'integrations': [
              {'source': source.path, 'channel': 'stable'},
            ],
          }),
        );
      final publisher =
          '${repository.path}/drivers/tools/publish/build_site.py';
      Future<void> publish(
        String output, {
        String? previous,
      }) => _run('python3', [
        publisher,
        '--index',
        index.path,
        '--output',
        '${temporary.path}/$output',
        '--key',
        key,
        '--key-id',
        'ci-fixture',
        '--published-at',
        output == 'site-1' ? '2026-11-11T21:25:00Z' : '2026-11-12T08:00:00Z',
        if (previous != null) ...['--previous', '${temporary.path}/$previous'],
      ]);
      await publish('site-1');
      await _run('python3', [
        '${repository.path}/drivers/tools/publish/refresh_seed.py',
        '--site',
        '${temporary.path}/site-1',
        '--public-key',
        public.path,
        '--output',
        '${temporary.path}/seed',
      ]);

      final server = StaticDriverServer();
      await server.start();
      addTearDown(server.close);
      final scratch = await Directory('${temporary.path}/verify').create();
      final service = IntegrationService(
        root: Directory('${temporary.path}/app/installed-drivers'),
        engines: ProtocolEngineRegistry([SsapEngine()]),
        credentials: _NoCredentials(),
        verify: OpensslVerifier(public, scratch).call,
        source: DriverHttpSource(server.base, allowLoopbackHttp: true),
      );
      final registry = ProviderRegistry();
      await service.initialize(registry, seed: _seed('${temporary.path}/seed'));
      expect(server.requests, isEmpty);
      expect(registry.isRegistered('lg.webos'), isTrue);
      final seeded = (await service.installer.inventory())['lg.webos.22-plus']!;
      final generation = await service.installer.load('lg.webos.22-plus');
      expect(generation!.record.source, 'seed');
      expect(seeded.lastUpdatedAt, DateTime.utc(2026, 11, 11, 21, 25));

      final mappings = File('${source.path}/mappings.json');
      final edited = jsonDecode(mappings.readAsStringSync()) as Map;
      (edited['volume-up'] as Map)['uri'] = 'ssap://audio/setVolume';
      mappings.writeAsStringSync(jsonEncode(edited));
      await publish('site-2', previous: 'site-1');
      _serve(server, '${temporary.path}/site-2');
      final report = await service.updates.checkNow();
      final updated = report.updated['lg.webos.22-plus']!;
      expect(updated, isNot(seeded.current));
      final plan = await service.planner.prepare(
        RemoteDevice(id: 'lg.webos:uuid:x', name: 'TV', providerId: 'lg.webos'),
      );
      expect(plan.sha256, updated);
      expect(
        plan.definition
            .operations(plan.profile)['volume-up']!
            .operation
            .describe()['uri'],
        'ssap://audio/setVolume',
      );
      expect(
        (await service.installer.rollback('lg.webos.22-plus')).current,
        seeded.current,
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

SeedBundle _seed(String directory) {
  final index =
      jsonDecode(File('$directory/seed.json').readAsStringSync()) as Map;
  return SeedBundle(File('$directory/catalog.json').readAsStringSync(), {
    for (final sha in (index['objects'] as List).cast<String>())
      sha: Uint8List.fromList(
        File('$directory/objects/$sha.zip').readAsBytesSync(),
      ),
  });
}

void _serve(StaticDriverServer server, String site) {
  for (final file in Directory(
    site,
  ).listSync(recursive: true).whereType<File>()) {
    server.files[file.path.substring(site.length + 1)] = file.readAsBytesSync();
  }
}

final class _NoCredentials implements CredentialStore {
  @override
  Future<void> delete(String id) async {}
  @override
  Future<String?> read(String id) async => null;
  @override
  Future<void> write(String id, String key) async {}
}
