import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/devices.dart';
import 'package:remote_driver_runtime/integrations.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';

import '../catalog/catalog_integration.dart';
import '../catalog/integration_catalog.dart';
import '../distribution/driver_http_source.dart';
import '../distribution/driver_signature_verifier.dart';
import '../installation/http_integration_package_source.dart';
import '../installation/installed_integration.dart';
import '../installation/integration_catalog_repository.dart';
import '../installation/integration_installer.dart';
import '../installation/integration_package.dart';
import '../installation/integration_update_report.dart';
import '../installation/integration_update_service.dart';
import '../installation/legacy_driver_storage_migration.dart';
import '../installation/migrate_legacy_device_metadata.dart';
import '../installation/package_verifier.dart';
import '../installation/seed_bundle.dart';
import '../installation/stored_zip_writer.dart';
import '../installation/unavailable_package_source.dart';
import '../installation/update_schedule.dart';
import '../installation/verified_object.dart';
import '../providers/integration_provider_source.dart';
import '../providers/provider_rule_source.dart';
import '../selection/managed_integration_planner.dart';

/// The application's single entry point to driver integrations: storage
/// migration, provider registration, installation, updates and planning.
final class IntegrationService {
  IntegrationService({
    required this.root,
    required this.engines,
    required this.credentials,
    required DriverSignatureVerifier verify,
    DriverHttpSource? source,
    this.legacyRoot,
    DiscoveryNetwork network = const IoDiscoveryNetwork(),
    this.allowDevelopment = false,
  }) : _verify = verify,
       catalogs = IntegrationCatalogRepository(source, root, verify) {
    installer = IntegrationInstaller(root, inUse: (id) => planner.inUse(id));
    updates = IntegrationUpdateService(
      catalogs: catalogs,
      packages: source == null
          ? const UnavailablePackageSource()
          : HttpIntegrationPackageSource(source),
      verifier: PackageVerifier(verify, validate: _validate),
      installer: installer,
      schedule: UpdateSchedule(root),
      allowDevelopment: allowDevelopment,
      supportsRuntime: (requirement) => engines.missing(requirement).isEmpty,
    );
    planner = ManagedIntegrationPlanner(
      installer: installer,
      catalogs: catalogs,
      updates: updates,
      engines: engines,
      allowDevelopment: allowDevelopment,
    );
    _providers = IntegrationProviderSource(
      engines: engines,
      network: network,
      createController: (device) => GenericTvController(
        device,
        planner: planner,
        credentials: credentials,
      ),
      allowDevelopment: allowDevelopment,
    );
  }

  final Directory root;
  final Directory? legacyRoot;
  final ProtocolEngineRegistry engines;
  final CredentialStore credentials;
  final bool allowDevelopment;
  final IntegrationCatalogRepository catalogs;
  final DriverSignatureVerifier _verify;
  late final IntegrationInstaller installer;
  late final IntegrationUpdateService updates;
  late final ManagedIntegrationPlanner planner;
  late final IntegrationProviderSource _providers;

  /// Migrates retired storage, installs missing integrations from the
  /// signed [seed], and registers providers from installed packages and the
  /// cached catalog. Never touches the network.
  Future<void> initialize(ProviderRegistry registry, {SeedBundle? seed}) async {
    final legacy = legacyRoot;
    if (legacy != null) {
      await LegacyDriverStorageMigration(
        legacyRoot: legacy,
        root: root,
      ).migrate();
    }
    if (seed != null) {
      await installSeed(seed);
    }
    await register(registry);
  }

  /// Installs seeded integrations that are not installed yet, through the
  /// same verification as downloads. Installed generations and newer cached
  /// catalogs always win over the seed.
  Future<List<String>> installSeed(SeedBundle seed) async {
    final catalog = await IntegrationCatalog.verify(seed.envelope, _verify);
    await catalogs.adopt(seed.envelope);
    final installed = await installer.inventory();
    final result = <String>[];
    for (final entry in catalog.integrations) {
      final bytes = seed.objects[entry.sha256];
      if (installed[entry.id]?.current != null ||
          bytes == null ||
          (entry.development && !allowDevelopment)) {
        continue;
      }
      final (package, record) = await updates.verifier.verify(
        entry,
        bytes,
        keyId: catalog.keyId,
        catalogRevision: catalog.revision,
        source: 'seed',
        now: DateTime.now().toUtc(),
      );
      await installer.install(package, record);
      result.add(entry.id);
    }
    return result;
  }

  /// Fetches the signed catalog and re-registers providers.
  Future<void> refresh(ProviderRegistry registry) async {
    await catalogs.refresh();
    await register(registry);
  }

  /// Hash-based update check, at most once per day.
  Future<IntegrationUpdateReport> checkUpdates(
    ProviderRegistry registry,
  ) async {
    final report = await updates.checkIfDue();
    await register(registry);
    return report;
  }

  Future<void> register(ProviderRegistry registry) async {
    for (final definition in _providers.definitions(await _sources())) {
      registry.replaceDefinition(definition);
    }
  }

  /// Installs an unpublished local integration (development builds only).
  Future<InstalledIntegration> installLocal(Map<String, String> files) async {
    final package = IntegrationPackage.read(storedZip(files));
    _validate(package);
    final now = DateTime.now().toUtc();
    return installer.install(
      package,
      VerifiedObject(
        sha256: package.sha256,
        identity: package.identity,
        lastUpdatedAt: package.manifest.lastUpdatedAt ?? now,
        size: package.bytes.length,
        verifiedAt: now,
        source: 'local',
      ),
    );
  }

  /// Installs every integration folder below [directory] that has a
  /// manifest (development builds only).
  Future<void> installLocalFolder(Directory directory) async {
    final manifests = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.uri.pathSegments.last == 'manifest.json');
    for (final manifest in manifests) {
      await installLocal(_folder(manifest.parent));
    }
  }

  static Map<String, String> _folder(Directory directory) {
    final root = directory.path;
    return {
      for (final file in directory.listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.json'))
          file.path.substring(root.length + 1): file.readAsStringSync(),
    };
  }

  /// Rewrites version-based driver metadata on a saved device.
  Future<RemoteDevice> migrateDevice(RemoteDevice device) async {
    final migrated = migrateLegacyDeviceMetadata(
      device.metadata,
      catalog: await _cachedCatalog(),
    );
    return identical(migrated, device.metadata)
        ? device
        : copyDevice(device, metadata: migrated);
  }

  /// Deletes integration-scoped credentials kept for [device].
  Future<void> clearCredentials(RemoteDevice device) async {
    for (final id in (await installer.inventory()).keys) {
      await credentials.delete('$id:${device.id}');
    }
  }

  Future<List<ProviderRuleSource>> _sources() async {
    final sources = <String, ProviderRuleSource>{};
    for (final record in (await installer.inventory()).values) {
      final generation = await installer.load(record.integrationId);
      if (generation == null) {
        continue;
      }
      try {
        sources[record.integrationId] = ProviderRuleSource.definition(
          IntegrationDefinition.compile(generation.package.files, engines),
        );
      } on FormatException {
        continue;
      }
    }
    final catalog = await _cachedCatalog();
    for (final entry in catalog?.integrations ?? const <CatalogIntegration>[]) {
      sources.putIfAbsent(entry.id, () => ProviderRuleSource.catalog(entry));
    }
    return sources.values.toList();
  }

  Future<IntegrationCatalog?> _cachedCatalog() async {
    try {
      return await catalogs.cached();
    } on FormatException {
      return null;
    }
  }

  void _validate(IntegrationPackage package) =>
      IntegrationDefinition.compile(package.files, engines);
}
