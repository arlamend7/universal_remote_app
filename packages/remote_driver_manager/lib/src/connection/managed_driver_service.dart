import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';
import 'package:remote_network/remote_network.dart';

import '../distribution/driver_catalog.dart';
import '../distribution/driver_catalog_repository.dart';
import '../distribution/driver_release.dart';
import '../lifecycle/driver_manager.dart';
import '../resolution/driver_candidate.dart';
import '../resolution/driver_resolver.dart';
import 'managed_tv_provider.dart';

/// Registers signed declarative providers in the app's existing registry.
final class ManagedDriverService {
  ManagedDriverService(this.manager, this.catalogs, {DriverRuntime? runtime})
    : runtime = runtime ?? const DriverRuntime();

  final DriverManager manager;
  final DriverCatalogRepository catalogs;
  final DriverRuntime runtime;
  final _resolver = DriverResolver(
    runtimeVersion: DriverRuntime.version,
    operations: DriverRuntime.operations,
  );
  DriverCatalog? _catalog;

  DriverCatalog? get catalog => _catalog;

  Future<void> initialize(ProviderRegistry registry) async {
    await manager.initialize();
    _register(registry);
    try {
      _catalog = await catalogs.cached();
    } on FormatException {
      // Installed packages stay usable when catalog metadata is damaged.
      return;
    }
    _register(registry);
  }

  Future<void> refresh(ProviderRegistry registry) async {
    _catalog = await catalogs.refresh();
    _register(registry);
  }

  void _register(ProviderRegistry registry) {
    final ids = {
      for (final bundle in _installed) bundle.manifest.identity.providerId,
      for (final release in _releases)
        if (release.discovery != null) release.manifest.identity.providerId,
    };
    for (final id in ids) {
      if (id == ProviderIdentity.roku.storageId || registry.isRegistered(id)) {
        continue;
      }
      final provider = ManagedTvProvider(id, this);
      registry.registerDefinition(provider.definition);
    }
  }

  Iterable<DriverBundle> get _installed =>
      manager.inventory.keys.map(manager.active).nonNulls;

  Iterable<({DriverManifest manifest, DriverDiscoveryRules rules})>
  descriptions(String providerId) sync* {
    for (final bundle in _installed) {
      if (bundle.manifest.identity.providerId == providerId) {
        yield (manifest: bundle.manifest, rules: bundle.discovery);
      }
    }
    for (final release in _releases) {
      if (release.manifest.identity.providerId == providerId &&
          release.discovery != null) {
        yield (manifest: release.manifest, rules: release.discovery!);
      }
    }
  }

  Iterable<DriverCandidate> _candidates(String providerId) sync* {
    for (final bundle in _installed) {
      if (bundle.manifest.identity.providerId == providerId) {
        yield DriverCandidate(bundle.manifest, installed: true);
      }
    }
    for (final release in _releases) {
      if (release.manifest.identity.providerId == providerId &&
          manager.inventory[release.manifest.identity.id]?.enabled != false) {
        yield DriverCandidate(release.manifest);
      }
    }
  }

  Future<DriverBundle> prepare(
    RemoteDevice device, {
    required bool Function() cancelled,
    void Function()? onInstalling,
  }) async {
    final evidence = DriverDeviceEvidence.fromDevice(
      device,
      osVersion: device.metadata['osVersion'],
      firmwareVersion: device.metadata['firmwareVersion'],
    );
    var result = _resolver.resolve(evidence, _candidates(device.providerId));
    if (result.selected?.candidate.installed != true &&
        !result.requiresSelection &&
        !cancelled()) {
      try {
        _catalog = await catalogs.refresh();
      } on Exception {
        if (result.selected == null) {
          rethrow;
        }
      }
      result = _resolver.resolve(evidence, _candidates(device.providerId));
    }
    if (cancelled()) {
      throw const RemoteException('cancelled', 'Driver connection cancelled.');
    }
    if (result.requiresSelection) {
      throw const RemoteException(
        'driverAmbiguous',
        'Multiple driver families match this TV.',
      );
    }
    final candidate = result.selected?.candidate;
    if (candidate == null) {
      throw const RemoteException(
        'driverUnavailable',
        'No compatible driver is available.',
      );
    }
    if (candidate.installed) {
      return manager.active(candidate.identity.id)!;
    }
    onInstalling?.call();
    return manager.install(candidate.identity, cancelled: cancelled);
  }

  Iterable<DriverRelease> get _releases =>
      (_catalog?.releases ?? const <DriverRelease>[]).where(
        (release) => !release.development,
      );
}
