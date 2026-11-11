import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';
import 'package:test/test.dart';

import 'fixture_driver_signer.dart';
import 'fixture_driver_repository.dart';

Future<String> _signCatalog(
  FixtureDriverSigner signer,
  Map<String, Object?> release,
  int revision, {
  Map<String, Object?>? alternative,
}) async {
  final payload = utf8.encode(
    jsonEncode({
      'schemaVersion': 1,
      'revision': revision,
      'publishedAt': '2026-01-01T00:00:00Z',
      'releases': [release, if (alternative != null) alternative],
    }),
  );
  return jsonEncode({
    'keyId': 'fixture-key',
    'payload': base64Encode(payload),
    'signature': base64Encode(await signer.sign(payload)),
  });
}

void main() {
  test('managed commands bind inputs and publish typed feedback', () async {
    final directory = await Directory.systemTemp.createTemp('driver-commands-');
    addTearDown(() => directory.delete(recursive: true));
    final fixture = await LocalDriverPackageRepository.open(
      Directory('drivers/providers/example-tv'),
      enabled: true,
    );
    final files = fixture.package.files;
    final manifest = fixture.package.bundle.manifest.toJson();
    final commands = {
      'set-volume': _commandFile('setVolume', {
        'level': {r'$argument': 'volume'},
      }),
      'read-volume': _commandFile('readVolume'),
      'list-applications': _commandFile('listApplications'),
      'launch-application': _commandFile('launchApplication', {
        'app': {r'$argument': 'target'},
      }),
    };
    final package = DriverPackage({
      ...files,
      'manifest.json': jsonEncode({
        ...manifest,
        'capabilities': [
          'volume',
          'absoluteVolume',
          'volumeFeedback',
          'applications',
        ],
      }),
      'capabilities.json': jsonEncode({
        'volume': ['volume-up', 'volume-down'],
        'absoluteVolume': ['set-volume'],
        'volumeFeedback': ['read-volume'],
        'applications': ['list-applications', 'launch-application'],
      }),
      for (final entry in commands.entries)
        'commands/${entry.key}.json': entry.value,
    });
    final manager = DriverManager(
      DriverPackageStorage(directory),
      FixtureDriverRepository([package]),
    );
    await manager.initialize();
    await manager.install(package.identity);
    final sent = <String>[];
    final payloads = <Map<String, Object?>>[];
    final runtime = await _fixtureTv(
      sent,
      onRequest: (request) {
        payloads.add(request);
        return switch (request['command']) {
          'readVolume' => {'volume': 42, 'muted': false},
          'listApplications' => {
            'applications': [
              {'id': 'example.app', 'name': 'Example App'},
            ],
          },
          _ => {'ok': true},
        };
      },
    );
    final registry = ProviderRegistry();
    await ManagedDriverService(
      manager,
      null,
      runtime: runtime,
    ).initialize(registry);
    final device = registry.createManualDevice(
      address: '192.168.1.20',
      name: 'TV',
      legacy: false,
      allowInsecurePointer: false,
    );
    final remote = registry.createController(device) as TVRemoteBase;
    addTearDown(remote.dispose);
    await remote.connect();
    expect(remote.supports(RemoteCapability.absoluteVolume), isTrue);
    expect(remote.supports(RemoteCapability.navigation), isFalse);
    expect(() => remote.setVolume(101), throwsRangeError);
    await remote.setVolume(42);
    final observed = remote.watchVolume().first;
    expect((await remote.readVolume()).volume, 42);
    expect((await observed).muted, isFalse);
    expect((await remote.applications()).single.name, 'Example App');
    expect(remote.reportedApplicationIds, {'example.app'});
    await remote.launchApplication('example.app');
    await expectLater(remote.inputs(), throwsA(isA<RemoteException>()));
    expect(sent, [
      'setVolume',
      'readVolume',
      'listApplications',
      'launchApplication',
    ]);
    expect(payloads.first['level'], 42);
    expect(payloads.last['app'], 'example.app');
  });

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
      final alternative = {
        ...release,
        'manifest': {
          ...manifest as Map<String, Object?>,
          'id': 'example.alternate',
        },
        'package': 'packages/example.alternate/1.0.0/driver.zip',
      };
      final envelope = await _signCatalog(
        signer,
        release,
        2,
        alternative: alternative,
      );
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

      final identity = results.first.releases.first.manifest.identity;
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
      final remote = registry.createController(tv) as ManagedTvController;
      final asking = remote.connectionStates.firstWhere(
        (state) => state == DeviceConnectionState.pairing,
      );
      final connecting = remote.connect();
      await asking.timeout(const Duration(seconds: 2));
      expect(remote.choices, hasLength(2));
      expect(packageRequests, 1);
      remote.chooseDriver(
        remote.choices.singleWhere(
          (match) => match.candidate.identity.id == identity.id,
        ),
      );
      await connecting;
      expect(remote.device.metadata['managedDriverId'], identity.id);
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

String _commandFile(String action, [Map<String, Object> data = const {}]) =>
    jsonEncode([
      {'operation': 'websocket.connect'},
      {
        'operation': 'websocket.sendJson',
        'payload': {'command': action, ...data},
      },
      {'operation': 'websocket.awaitJson'},
      {'operation': 'websocket.disconnect'},
    ]);

Future<DriverRuntime> _fixtureTv(
  List<String> commands, {
  Map<String, Object?> Function(Map<String, Object?>)? onRequest,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  addTearDown(() => server.close(force: true));
  final listener = server.listen((request) async {
    // The runtime owns closure of the peer connection.
    // ignore: close_sinks
    final socket = await WebSocketTransformer.upgrade(request);
    socket.listen((message) {
      final command = jsonDecode(message as String) as Map<String, Object?>;
      commands.add(command['command'] as String);
      socket.add(jsonEncode(onRequest?.call(command) ?? {'ok': true}));
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
