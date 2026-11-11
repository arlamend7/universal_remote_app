import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';
import 'package:test/test.dart';

import 'fixture_driver_signer.dart';

Future<String> _signCatalog(
  FixtureDriverSigner signer,
  Map<String, Object?> release,
  int revision,
) async {
  final payload = utf8.encode(
    jsonEncode({
      'schemaVersion': 1,
      'revision': revision,
      'publishedAt': '2026-01-01T00:00:00Z',
      'releases': [release],
    }),
  );
  return jsonEncode({
    'keyId': 'fixture-key',
    'payload': base64Encode(payload),
    'signature': base64Encode(await signer.sign(payload)),
  });
}

void main() {
  test(
    'signed catalog and package verify, cache, deduplicate and install',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'driver-distribution-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final signer = FixtureDriverSigner(directory);
      await signer.initialize();
      final zip = File('${directory.path}/driver.zip');
      final built = await Process.run('python3', [
        'drivers/tools/package/build.py',
        'drivers/providers/example-tv',
        zip.path,
      ]);
      expect(built.exitCode, 0, reason: '${built.stderr}');
      final bytes = await zip.readAsBytes();
      final manifest = jsonDecode(
        await File('drivers/providers/example-tv/manifest.json').readAsString(),
      );
      const path = 'packages/example.smarttv/1.0.0/driver.zip';
      final release = <String, Object?>{
        'manifest': manifest,
        'discovery': jsonDecode(
          await File('drivers/providers/example-tv/discovery.json')
              .readAsString(),
        ),
        'package': path,
        'size': bytes.length,
        'sha256': sha256.convert(bytes).toString(),
        'signature': base64Encode(await signer.sign(bytes)),
        'channel': 'stable',
      };
      final envelope = await _signCatalog(signer, release, 2);
      var body = envelope;
      var corruptPackage = false;
      var honorEtag = true;
      var catalogRequests = 0;
      var packageRequests = 0;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final listener = server.listen((request) {
        final response = request.response;
        if (request.uri.path == '/catalog.json') {
          catalogRequests++;
          _catalogResponse(request, response, body, honorEtag);
        } else if (request.uri.path == '/$path') {
          packageRequests++;
          response.add(corruptPackage ? List.filled(bytes.length, 0) : bytes);
        } else {
          response.statusCode = HttpStatus.notFound;
        }
        response.close();
      });
      addTearDown(listener.cancel);
      final source = DriverHttpSource(
        Uri.parse('http://127.0.0.1:${server.port}/'),
        allowLoopbackHttp: true,
      );
      final storage = DriverPackageStorage(
        Directory('${directory.path}/installed'),
      );
      final catalogs = DriverCatalogRepository(source, storage, signer.verify);
      final results = await Future.wait([
        catalogs.refresh(),
        catalogs.refresh(),
      ]);
      expect(results.first.revision, 2);
      expect(catalogRequests, 1);
      expect((await catalogs.refresh()).revision, 2);
      expect(catalogRequests, 2);
      expect(packageRequests, 0);

      final identity = results.first.releases.single.manifest.identity;
      final packages = HttpDriverPackageRepository(
        source,
        catalogs,
        signer.verify,
      );
      final downloads = await Future.wait([
        packages.fetch(identity),
        packages.fetch(identity),
      ]);
      expect(downloads.first.bundle.commands.keys, [
        'volume-up',
        'volume-down',
      ]);
      expect(packageRequests, 1);
      final manager = DriverManager(storage, packages);
      final commands = <String>[];
      final runtime = await _fixtureTv(commands);
      final registry = ProviderRegistry();
      final drivers = ManagedDriverService(manager, catalogs, runtime: runtime);
      await drivers.initialize(registry);
      expect(packageRequests, 1);
      final discovery = DiscoveryRegistry()
        ..register(
          DiscoveryProtocol.bonjour,
          (_, _, observe) => observe(
            DiscoveryObservation(
              protocolId: DiscoveryProtocol.bonjour,
              serviceType: '_example-tv._tcp',
              endpoint: Uri.parse('wss://192.168.1.20:9000'),
            ),
          ),
        );
      final discovered = await DiscoveryManager(
        discovery,
        registry.definitions.map((definition) => definition.identifier),
      ).discover();
      final tv = discovered.devices.single;
      expect(packageRequests, 1);
      final remote = registry.createController(tv) as TVRemoteBase;
      await remote.connect();
      await remote.volumeUp();
      await remote.dispose();
      expect(commands, ['volumeUp']);
      expect(
        manager.active(identity.id)?.manifest.identity.version,
        identity.version,
      );
      expect(packageRequests, 2);

      corruptPackage = true;
      await expectLater(packages.fetch(identity), throwsFormatException);
      honorEtag = false;
      body = await _signCatalog(signer, release, 1);
      await expectLater(catalogs.refresh(), throwsFormatException);
      body = envelope.replaceFirst('fixture-key', 'unknown-key');
      await expectLater(catalogs.refresh(), throwsFormatException);
      body = '{bad json';
      await expectLater(catalogs.refresh(), throwsFormatException);
      await server.close(force: true);
      expect((await catalogs.cached())?.revision, 2);
      final offline = DriverManager(storage, packages);
      final offlineRegistry = ProviderRegistry();
      await ManagedDriverService(
        offline,
        catalogs,
        runtime: runtime,
      ).initialize(offlineRegistry);
      final manual = offlineRegistry.createManualDevice(
        address: '192.168.1.20',
        name: 'Offline TV',
        legacy: false,
        allowInsecurePointer: false,
      );
      final offlineRemote =
          offlineRegistry.createController(manual) as TVRemoteBase;
      await offlineRemote.connect();
      await offlineRemote.volumeDown();
      await offlineRemote.dispose();
      expect(commands, ['volumeUp', 'volumeDown']);
    },
  );
}

void _catalogResponse(
  HttpRequest request,
  HttpResponse response,
  String body,
  bool honorEtag,
) {
  const etag = '"fixture-v2"';
  if (honorEtag &&
      request.headers.value(HttpHeaders.ifNoneMatchHeader) == etag) {
    response.statusCode = HttpStatus.notModified;
    return;
  }
  response.headers.set(HttpHeaders.etagHeader, etag);
  response.write(body);
}

Future<DriverRuntime> _fixtureTv(List<String> commands) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  addTearDown(() => server.close(force: true));
  final listener = server.listen((request) async {
    // The runtime owns closure of the peer connection.
    // ignore: close_sinks
    final socket = await WebSocketTransformer.upgrade(request);
    socket.listen((message) {
      final command = jsonDecode(message as String) as Map<String, Object?>;
      commands.add(command['command'] as String);
      socket.add('{"ok":true}');
    });
  });
  addTearDown(listener.cancel);
  return DriverRuntime(
    connect:
        (_, {required cancellation, required timeout, trustedCertificateDer}) =>
            IoWebSocketTransport.connect(
              Uri.parse('ws://127.0.0.1:${server.port}'),
              timeout: timeout,
              cancellation: cancellation,
            ),
  );
}
