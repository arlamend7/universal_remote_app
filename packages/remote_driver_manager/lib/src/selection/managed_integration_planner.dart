import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/integrations.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';

import '../catalog/catalog_integration.dart';
import '../catalog/integration_catalog.dart';
import '../installation/installed_generation.dart';
import '../installation/integration_catalog_repository.dart';
import '../installation/integration_installer.dart';
import '../installation/integration_metadata_keys.dart';
import '../installation/integration_update_service.dart';
import 'device_software_evidence.dart';
import 'integration_candidate.dart';
import 'integration_resolver.dart';
import 'integration_selection.dart';
import 'selection_stage.dart';

/// Resolves a device's integration before its session starts: chooses a
/// compatible integration, installs it when missing, loads the verified
/// generation and compiles it against the engines of this runtime.
final class ManagedIntegrationPlanner implements IntegrationPlanner {
  ManagedIntegrationPlanner({
    required this.installer,
    required this.catalogs,
    required this.updates,
    required this.engines,
    this.allowDevelopment = false,
  });

  final IntegrationInstaller installer;
  final IntegrationCatalogRepository catalogs;
  final IntegrationUpdateService updates;
  final ProtocolEngineRegistry engines;
  final bool allowDevelopment;
  final _inUse = <String, int>{};
  final _compiled = <String, IntegrationDefinition>{};

  /// Whether a session currently uses [integrationId]; the installer stages
  /// updates for such integrations instead of swapping them.
  bool inUse(String integrationId) => (_inUse[integrationId] ?? 0) > 0;

  @override
  Future<IntegrationPlan> prepare(
    RemoteDevice device, {
    void Function(double? progress)? onProgress,
  }) async {
    final assigned = await _assigned(device);
    final selection =
        _bootstrap(device, await _candidates(), assigned) ??
        _bootstrap(device, await _candidates(refresh: true), assigned);
    if (selection == null) {
      throw const RemoteException(
        'driverMissing',
        'No driver integration supports this TV yet.',
      );
    }
    return _plan(selection, onProgress: onProgress);
  }

  IntegrationSelection? _bootstrap(
    RemoteDevice device,
    List<IntegrationCandidate> candidates,
    String? assigned,
  ) => IntegrationResolver.bootstrap(
    device.providerId,
    candidates,
    model: device.model,
    assigned: assigned,
    allowDevelopment: allowDevelopment,
  );

  @override
  Future<IntegrationPlan> refine(
    IntegrationPlan current,
    RemoteDevice device,
    DeviceSoftwareInformation? software,
  ) async {
    final candidates = await _candidates();
    final selected = candidates
        .where((candidate) => candidate.id == current.identity.integrationId)
        .firstOrNull;
    if (selected == null) {
      return current;
    }
    final refined = IntegrationResolver.identified(
      IntegrationSelection(
        selected,
        current.profile,
        SelectionStage.bootstrap,
        reason: 'current',
      ),
      candidates,
      DeviceSoftwareEvidence.of(software, model: device.model),
      allowDevelopment: allowDevelopment,
    );
    if (refined.identity == current.identity &&
        refined.profile.id == current.profile.id) {
      return current;
    }
    return _plan(refined);
  }

  @override
  Future<void> remember(IntegrationPlan plan, RemoteDevice device) async {
    _inUse.update(
      plan.identity.integrationId,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    await installer.assign(plan.identity, device.id, plan.profile.id);
  }

  @override
  void release(IntegrationPlan plan) {
    final id = plan.identity.integrationId;
    final remaining = (_inUse[id] ?? 1) - 1;
    if (remaining > 0) {
      _inUse[id] = remaining;
      return;
    }
    _inUse.remove(id);
    installer.activateStaged(id).ignore();
  }

  Future<IntegrationPlan> _plan(
    IntegrationSelection selection, {
    void Function(double? progress)? onProgress,
  }) async {
    final generation = await _generation(selection, onProgress);
    final definition = _compiled[generation.sha256] ??=
        IntegrationDefinition.compile(generation.package.files, engines);
    final profile = definition.profile(selection.profile.id);
    return IntegrationPlan(
      definition,
      profile,
      sha256: generation.sha256,
      identified: selection.stage == SelectionStage.identified,
      metadata: {
        IntegrationMetadataKeys.integrationId:
            definition.identity.integrationId,
        IntegrationMetadataKeys.profileId: profile.id,
        IntegrationMetadataKeys.packageSha256: generation.sha256,
      },
    );
  }

  Future<InstalledGeneration> _generation(
    IntegrationSelection selection,
    void Function(double? progress)? onProgress,
  ) async {
    final id = selection.identity.integrationId;
    if (!inUse(id)) {
      await installer.activateStaged(id);
    }
    final installed = await installer.load(id);
    if (installed != null) {
      return installed;
    }
    final entry = await _catalogEntry(id);
    onProgress?.call(null);
    await updates.installFromCatalog(
      entry.$1,
      entry.$2,
      onBytes: (bytes) => onProgress?.call(bytes / entry.$1.size),
    );
    final loaded = await installer.load(id);
    if (loaded == null) {
      throw const RemoteException(
        'driverMissing',
        'The driver integration could not be installed.',
      );
    }
    return loaded;
  }

  Future<(CatalogIntegration, IntegrationCatalog)> _catalogEntry(
    String id,
  ) async {
    final catalog = await catalogs.cached() ?? await catalogs.refresh();
    final entry = catalog.integration(id);
    if (entry == null) {
      throw const RemoteException(
        'driverMissing',
        'The driver integration is not published.',
      );
    }
    return (entry, catalog);
  }

  Future<String?> _assigned(RemoteDevice device) async {
    final saved = device.metadata[IntegrationMetadataKeys.integrationId];
    if (saved != null) {
      return saved;
    }
    for (final record in (await installer.inventory()).values) {
      if (record.assignments.containsKey(device.id)) {
        return record.integrationId;
      }
    }
    return null;
  }

  /// Installed packages first (offline), then catalog entries; the catalog
  /// is fetched only when [refresh] is set because nothing local matched.
  Future<List<IntegrationCandidate>> _candidates({bool refresh = false}) async {
    final result = <String, IntegrationCandidate>{};
    for (final record in (await installer.inventory()).values) {
      final generation = await installer.load(record.integrationId);
      if (generation != null) {
        result[record.integrationId] = IntegrationCandidate.manifest(
          generation.package.manifest,
        );
      }
    }
    final catalog = refresh
        ? await _refreshedCatalog()
        : await _cachedCatalog();
    for (final entry in catalog?.integrations ?? const <CatalogIntegration>[]) {
      if (engines.missing(entry.runtime).isEmpty) {
        result.putIfAbsent(entry.id, () => IntegrationCandidate.catalog(entry));
      }
    }
    return result.values.toList();
  }

  Future<IntegrationCatalog?> _refreshedCatalog() async {
    try {
      return await catalogs.refresh();
    } on Object {
      // Offline or misconfigured: local discovery and installed drivers
      // keep working; the caller reports the missing integration.
      return _cachedCatalog();
    }
  }

  Future<IntegrationCatalog?> _cachedCatalog() async {
    try {
      return await catalogs.cached();
    } on FormatException {
      return null;
    }
  }
}
