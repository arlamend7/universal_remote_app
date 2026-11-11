import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';
import 'package:remote_network/remote_network.dart';

import '../distribution/driver_catalog.dart';
import '../distribution/driver_catalog_repository.dart';
import '../distribution/driver_release.dart';
import '../lifecycle/driver_manager.dart';
import '../lifecycle/driver_update_service.dart';
import '../resolution/driver_candidate.dart';
import '../resolution/driver_resolver.dart';
import 'managed_tv_provider.dart';

/// Registers signed declarative providers in the app's existing registry.
final class ManagedDriverService {
  ManagedDriverService(
    this.manager,
    this.catalogs, {
    DriverRuntime? runtime,
    this.updates,
  }) : runtime = runtime ?? const DriverRuntime();

  final DriverManager manager;
  final DriverCatalogRepository? catalogs;
  final DriverRuntime runtime;
  final DriverUpdateService? updates;
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
      _catalog = await catalogs?.cached();
    } on FormatException {
      // Installed packages stay usable when catalog metadata is damaged.
      return;
    }
    _register(registry);
  }

  Future<void> refresh(ProviderRegistry registry) async {
    _catalog = await catalogs?.refresh();
    _register(registry);
  }

  Future<void> checkUpdates(
    ProviderRegistry registry,
    Iterable<RemoteDevice> devices,
  ) async {
    if (catalogs == null) {
      return;
    }
    await updates?.check(devices, () async {
      await refresh(registry);
      return _catalog!;
    });
  }

  void _register(ProviderRegistry registry) {
    final ids = {
      for (final bundle in _installed)
        if (!_compiled(bundle.manifest)) bundle.manifest.identity.providerId,
      for (final release in _releases)
        if (release.discovery != null && !_compiled(release.manifest))
          release.manifest.identity.providerId,
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
      if (bundle.manifest.identity.providerId == providerId &&
          !_compiled(bundle.manifest)) {
        yield (manifest: bundle.manifest, rules: bundle.discovery);
      }
    }
    for (final release in _releases) {
      if (release.manifest.identity.providerId == providerId &&
          !_compiled(release.manifest) &&
          release.discovery != null) {
        yield (manifest: release.manifest, rules: release.discovery!);
      }
    }
  }

  Iterable<DriverCandidate> _candidates(String providerId) sync* {
    for (final bundle in _installed) {
      if (bundle.manifest.identity.providerId == providerId &&
          !_compiled(bundle.manifest)) {
        yield DriverCandidate(bundle.manifest, installed: true);
      }
    }
    for (final release in _releases) {
      if (release.manifest.identity.providerId == providerId &&
          !_compiled(release.manifest) &&
          manager.inventory[release.manifest.identity.id]?.enabled != false) {
        yield DriverCandidate(release.manifest);
      }
    }
  }

  DriverBindings? bindingsFor(RemoteDevice device) {
    final candidates = _installed
        .where((bundle) => _compiled(bundle.manifest))
        .map((bundle) => DriverCandidate(bundle.manifest, installed: true));
    final match = _resolver.resolve(_evidence(device), candidates).selected;
    return match == null
        ? null
        : manager.active(match.candidate.identity.id)?.bindings;
  }

  Future<void> prepareBindings(RemoteDevice device) async {
    if (bindingsFor(device) != null) {
      return;
    }
    _catalog ??= await catalogs?.refresh();
    final candidates = _releases
        .where(
          (release) =>
              _compiled(release.manifest) &&
              manager.inventory[release.manifest.identity.id]?.enabled != false,
        )
        .map((release) => DriverCandidate(release.manifest));
    final match = _resolver.resolve(_evidence(device), candidates).selected;
    if (match != null) {
      await manager.install(match.candidate.identity);
    }
  }

  static bool _compiled(DriverManifest manifest) =>
      manifest.runtime.operations.contains(DriverOperation.compiledBindings);

  static DriverDeviceEvidence _evidence(RemoteDevice device) =>
      DriverDeviceEvidence.fromDevice(
        device,
        osVersion: device.metadata['osVersion'],
        firmwareVersion: device.metadata['firmwareVersion'],
      );

  Future<DriverBundle> prepare(
    RemoteDevice device, {
    required bool Function() cancelled,
    void Function()? onInstalling,
    Stream<void>? cancellation,
    void Function(double)? progress,
  }) async {
    final evidence = _evidence(device);
    var result = _resolver.resolve(evidence, _candidates(device.providerId));
    if (result.selected?.candidate.installed != true &&
        !result.requiresSelection &&
        !cancelled()) {
      try {
        _catalog = await catalogs?.refresh();
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
    return manager.install(
      candidate.identity,
      cancelled: cancelled,
      cancellation: cancellation,
      progress: progress,
    );
  }

  Iterable<DriverRelease> get _releases =>
      (_catalog?.releases ?? const <DriverRelease>[]).where(
        (release) => !release.development,
      );
}
