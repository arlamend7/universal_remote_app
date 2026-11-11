import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';
import 'package:remote_network/remote_network.dart';

import '../distribution/driver_catalog.dart';
import '../distribution/driver_catalog_repository.dart';
import '../distribution/driver_release.dart';
import '../lifecycle/driver_manager.dart';
import '../lifecycle/driver_update_service.dart';
import '../resolution/driver_candidate.dart';
import '../resolution/driver_match.dart';
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
  CredentialStore? _credentials;

  DriverCatalog? get catalog => _catalog;

  Future<void> initialize(
    ProviderRegistry registry, {
    CredentialStore? credentials,
  }) async {
    _credentials = credentials ?? _credentials;
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

  DriverCredentialScope? credentialScope(
    DriverBundle bundle,
    RemoteDevice device,
  ) {
    final store = _credentials;
    if (store == null) {
      return null;
    }
    return DriverCredentialScope(store, bundle.manifest.identity.id, device.id);
  }

  Future<void> clearCredentials(RemoteDevice device) async {
    final store = _credentials;
    if (store == null) {
      return;
    }
    final families = {
      ...manager.inventory.keys,
      if (device.metadata['managedDriverId'] case final id?) id,
    };
    for (final family in families) {
      await DriverCredentialScope(store, family, device.id).delete();
    }
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

  Iterable<DriverBundle> get _installed => manager.enabledBundles;

  DriverCandidate _localCandidate(DriverBundle bundle) {
    final identity = bundle.manifest.identity;
    return DriverCandidate(
      bundle.manifest,
      installed: true,
      preferred: manager.inventory[identity.id]?.active == identity.version,
    );
  }

  DriverMatch? _pinned(
    RemoteDevice device,
    Iterable<DriverCandidate> candidates,
  ) {
    final family = device.metadata['managedDriverId'];
    final version = device.metadata['managedDriverPinnedVersion'];
    if (family == null || version == null) {
      return null;
    }
    return _resolver
        .resolve(
          _evidence(device),
          candidates.where(
            (candidate) =>
                candidate.identity.id == family &&
                candidate.identity.version.toString() == version,
          ),
        )
        .selected;
  }

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
        yield _localCandidate(bundle);
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
        .map(_localCandidate);
    final match =
        _pinned(device, candidates) ??
        _resolver.resolve(_evidence(device), candidates).selected;
    if (match == null) {
      return null;
    }
    final identity = match.candidate.identity;
    final bundle = manager.installed(identity.id, identity.version);
    final bindings = bundle?.bindings;
    if (bundle == null || bindings == null) {
      return null;
    }
    return DriverBindings(
      bindings.commands,
      profileFor: (identified) => profileFor(bundle, identified),
      selection: {
        'managedDriverId': identity.id,
        'managedDriverVersion': identity.version.toString(),
        'managedDriverProfile': match.profile.id,
        'managedDriverProfileVersion': '${match.profile.version}',
      },
    );
  }

  Future<void> prepareBindings(
    RemoteDevice device, {
    required bool Function() cancelled,
    Stream<void>? cancellation,
  }) async {
    if (cancelled() || bindingsFor(device) != null) {
      return;
    }
    _catalog ??= await catalogs?.refresh();
    if (cancelled()) {
      return;
    }
    final candidates = _releases
        .where(
          (release) =>
              _compiled(release.manifest) &&
              manager.inventory[release.manifest.identity.id]?.enabled != false,
        )
        .map((release) => DriverCandidate(release.manifest));
    final match = _resolver.resolve(_evidence(device), candidates).selected;
    if (match != null) {
      await manager.install(
        match.candidate.identity,
        cancelled: cancelled,
        cancellation: cancellation,
        makeDefault: false,
      );
    }
  }

  static bool _compiled(DriverManifest manifest) =>
      manifest.runtime.operations.contains(DriverOperation.compiledBindings);

  DriverCompatibility? compatibleProfile(
    DriverBundle bundle,
    RemoteDevice device,
  ) => _resolver
      .resolve(_evidence(device), [
        DriverCandidate(bundle.manifest, installed: true),
      ])
      .selected
      ?.profile;

  DriverCompatibility profileFor(DriverBundle bundle, RemoteDevice device) {
    final profile = compatibleProfile(bundle, device);
    if (profile == null) {
      throw const RemoteException(
        'driverIncompatible',
        'This driver has no profile for the TV’s reported software.',
      );
    }
    return profile;
  }

  Future<DriverBundle?> prepareReplacement(
    DriverBundle bootstrap,
    RemoteDevice identified, {
    required bool Function() cancelled,
    required Stream<void> cancellation,
  }) async {
    final family = bootstrap.manifest.identity.id;
    final mustAuthenticate = bootstrap.exchanges.containsKey('authenticate');
    final candidates = _candidates(identified.providerId).where(
      (candidate) =>
          candidate.identity.id == family &&
          (!mustAuthenticate ||
              candidate.manifest.runtime.operations.contains(
                DriverOperation.webSocketAuthenticate,
              )),
    );
    final selected = _resolver
        .resolve(_evidence(identified), candidates)
        .selected;
    if (selected == null || cancelled()) {
      return null;
    }
    final identity = selected.candidate.identity;
    final bundle = selected.candidate.installed
        ? manager.installed(identity.id, identity.version)
        : await manager.install(
            identity,
            cancelled: cancelled,
            cancellation: cancellation,
            makeDefault: false,
          );
    if (mustAuthenticate &&
        bundle?.exchanges.containsKey('authenticate') != true) {
      throw const RemoteException(
        'driverIncompatible',
        'The replacement release cannot authenticate this TV.',
      );
    }
    return bundle;
  }

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
    Future<DriverMatch?> Function(List<DriverMatch>)? choose,
  }) async {
    final evidence = _evidence(device);
    var result = _resolver.resolve(evidence, _deviceCandidates(device));
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
      result = _resolver.resolve(evidence, _deviceCandidates(device));
    }
    if (cancelled()) {
      throw const RemoteException('cancelled', 'Driver connection cancelled.');
    }
    final pinned = _pinned(device, _deviceCandidates(device));
    final chosen =
        pinned ??
        (result.requiresSelection
            ? await choose?.call(result.alternatives)
            : result.selected);
    if (cancelled()) {
      throw const RemoteException('cancelled', 'Driver connection cancelled.');
    }
    if (pinned == null &&
        result.requiresSelection &&
        !result.alternatives.contains(chosen)) {
      throw const RemoteException(
        'driverAmbiguous',
        'Choose a compatible TV driver.',
      );
    }
    final candidate = chosen?.candidate;
    if (candidate == null) {
      throw const RemoteException(
        'driverUnavailable',
        'No compatible driver is available.',
      );
    }
    if (candidate.installed) {
      return manager.installed(
        candidate.identity.id,
        candidate.identity.version,
      )!;
    }
    onInstalling?.call();
    return manager.install(
      candidate.identity,
      cancelled: cancelled,
      cancellation: cancellation,
      progress: progress,
      makeDefault: false,
    );
  }

  Iterable<DriverCandidate> _deviceCandidates(RemoteDevice device) {
    final preferred = device.metadata['managedDriverId'];
    final candidates = _candidates(device.providerId).toList();
    final selected = candidates.where(
      (candidate) => candidate.identity.id == preferred,
    );
    return _resolver.resolve(_evidence(device), selected).selected == null
        ? candidates
        : selected;
  }

  Iterable<DriverRelease> get _releases =>
      (_catalog?.releases ?? const <DriverRelease>[]).where(
        (release) => !release.development,
      );
}
