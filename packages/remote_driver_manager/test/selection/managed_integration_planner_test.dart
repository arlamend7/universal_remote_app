import 'dart:convert';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';
import 'package:test/test.dart';

import '../fixture_driver_signer.dart';
import '../installation/support/integration_fixture.dart';
import '../installation/support/static_driver_server.dart';

void main() {
  late Directory directory;
  late FixtureDriverSigner signer;
  late StaticDriverServer server;
  late Directory root;
  late Uri base;
  final engines = ProtocolEngineRegistry([JsonWebSocketEngine()]);
  const profiles = ['bootstrap', 'example-os-9'];
  final device = RemoteDevice(
    id: 'example:tv-1',
    name: 'TV',
    providerId: 'example.smarttv',
    endpoints: [Uri.parse('wss://192.168.1.50:7443/remote')],
  );

  ManagedIntegrationPlanner planner({IntegrationInstaller? installer}) {
    late ManagedIntegrationPlanner result;
    final target =
        installer ??
        IntegrationInstaller(root, inUse: (id) => result.inUse(id));
    final source = DriverHttpSource(base, allowLoopbackHttp: true);
    final catalogs = IntegrationCatalogRepository(source, root, signer.verify);
    result = ManagedIntegrationPlanner(
      installer: target,
      catalogs: catalogs,
      updates: IntegrationUpdateService(
        catalogs: catalogs,
        packages: HttpIntegrationPackageSource(source),
        verifier: PackageVerifier(signer.verify),
        installer: target,
        schedule: UpdateSchedule(root),
      ),
      engines: engines,
    );
    return result;
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('planner');
    root = Directory('${directory.path}/installed-drivers');
    signer = FixtureDriverSigner(directory);
    await signer.initialize();
    server = StaticDriverServer();
    await server.start();
    base = server.base;
    final fixture = IntegrationFixture(signer.sign);
    final bytes = IntegrationFixture.package(profiles: profiles);
    final entry = await fixture.entry(bytes, profiles: profiles);
    server.files[entry['package']! as String] = bytes;
    server.files[IntegrationCatalogRepository.path] = utf8.encode(
      await fixture.envelope([entry]),
    );
  });

  tearDown(() async {
    await server.close();
    await directory.delete(recursive: true);
  });

  test('installs before the first session and then works offline', () async {
    final first = await planner().prepare(device);
    expect(first.identity.integrationId, 'example.json-websocket');
    expect(first.profile.id, 'bootstrap');
    expect(first.sha256, isNotNull);
    expect(first.metadata, {
      'driverIntegrationId': 'example.json-websocket',
      'driverProfileId': 'bootstrap',
      'driverPackageSha256': first.sha256,
    });
    await server.close();
    final offline = await planner().prepare(device);
    expect(offline.sha256, first.sha256);
  });

  test('refines the profile from identified software and records it', () async {
    final managed = planner();
    final bootstrap = await managed.prepare(device);
    final unknown = await managed.refine(bootstrap, device, null);
    expect(identical(unknown, bootstrap), isTrue);
    final refined = await managed.refine(
      bootstrap,
      device,
      DeviceSoftwareInformation(
        source: DeviceInformationSource.authenticatedSession,
        operatingSystemVersion: '9.2',
      ),
    );
    expect(refined.profile.id, 'example-os-9');
    expect(refined.identified, isTrue);
    await managed.remember(refined, device);
    expect(managed.inUse('example.json-websocket'), isTrue);
    final record = (await IntegrationInstaller(root).inventory()).values.single;
    expect(record.assignments[device.id]?.profileId, 'example-os-9');
    managed.release(refined);
    expect(managed.inUse('example.json-websocket'), isFalse);
  });

  test('a device of an unpublished provider is reported explicitly', () async {
    await expectLater(
      planner().prepare(
        RemoteDevice(id: 'x', name: 'X', providerId: 'unknown.provider'),
      ),
      throwsA(
        isA<RemoteException>().having((e) => e.code, 'code', 'driverMissing'),
      ),
    );
  });
}
