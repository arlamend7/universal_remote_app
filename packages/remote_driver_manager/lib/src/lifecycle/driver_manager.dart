import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';

import '../resolution/driver_version_resolver.dart';
import 'driver_installation.dart';
import 'driver_package.dart';
import 'driver_package_repository.dart';
import 'driver_package_storage.dart';

/// A single manager owns writes to its application-private package storage.
final class DriverManager {
  DriverManager(this._storage, this._repository);

  final DriverPackageStorage _storage;
  final DriverPackageRepository _repository;
  Map<String, DriverInstallation> _inventory = {};
  Map<(String, DriverVersion), DriverPackage> _installedPackages = {};
  Set<String> _unavailable = {};
  bool _initialized = false;
  Future<void> _queue = Future.value();

  Map<String, DriverInstallation> get inventory => Map.unmodifiable(_inventory);
  Set<String> get unavailable => Set.unmodifiable(_unavailable);
  DriverBundle? active(String id) {
    final record = _inventory[id];
    return record == null ? null : installed(id, record.active);
  }

  DriverBundle? installed(String id, DriverVersion version) =>
      _inventory[id]?.enabled == true
      ? _installedPackages[(id, version)]?.bundle
      : null;

  Iterable<DriverBundle> get enabledBundles => _installedPackages.values
      .where((package) => _inventory[package.identity.id]?.enabled == true)
      .map((package) => package.bundle);

  Future<void> initialize() => _serialize(() async {
    if (_initialized) {
      return;
    }
    final recorded = await _storage.readInventory();
    final inventory = <String, DriverInstallation>{};
    final packages = <(String, DriverVersion), DriverPackage>{};
    final unavailable = <String>{};
    for (final entry in recorded.values) {
      final recovered = await _recover(entry);
      if (recovered == null) {
        unavailable.add(entry.id);
        continue;
      }
      final (record, package) = recovered;
      inventory[record.id] = record;
      packages.addAll(await _loadVersions(record, package));
    }
    if (inventory.length != recorded.length ||
        inventory.values.any(
          (entry) => entry.active != recorded[entry.id]?.active,
        )) {
      await _storage.writeInventory(inventory.values);
    }
    _inventory = inventory;
    _installedPackages = packages;
    _unavailable = unavailable;
    _initialized = true;
  });

  Future<Map<(String, DriverVersion), DriverPackage>> _loadVersions(
    DriverInstallation record,
    DriverPackage active,
  ) async {
    final packages = {(record.id, record.active): active};
    for (final version in record.versions.difference({record.active})) {
      final package = await _validLocal(record.id, version);
      if (package != null &&
          package.identity.providerId == active.identity.providerId) {
        packages[(record.id, version)] = package;
      }
    }
    return packages;
  }

  Future<DriverBundle> install(
    DriverIdentity identity, {
    bool Function()? cancelled,
    Stream<void>? cancellation,
    void Function(double)? progress,
    DriverVersion? expectedActive,
    bool makeDefault = true,
  }) => _serialize(() async {
    _requireInitialized();
    _checkCancellation(cancelled);
    final current = _inventory[identity.id];
    if (expectedActive != null &&
        (current?.active != expectedActive || current?.enabled != true)) {
      throw const RemoteException(
        'driverChanged',
        'The active driver changed.',
      );
    }
    final local = await _validLocal(identity.id, identity.version);
    final package =
        local ??
        await _repository.fetch(
          identity,
          cancellation: cancellation,
          progress: progress,
        );
    _checkCancellation(cancelled);
    if (!_sameIdentity(identity, package.identity)) {
      throw const RemoteException(
        'driverIdentity',
        'The driver package identity does not match.',
      );
    }
    if (!_supported(package)) {
      throw const RemoteException(
        'driverRuntime',
        'This driver requires a different runtime.',
      );
    }
    final currentPackage = current == null
        ? null
        : _installedPackages[(identity.id, current.active)];
    if (currentPackage != null &&
        currentPackage.identity.providerId != identity.providerId) {
      throw const RemoteException(
        'driverIdentity',
        'A driver family cannot change providers.',
      );
    }
    await _storage.prepare(package);
    _checkCancellation(cancelled);
    if (current?.active == identity.version) {
      _installedPackages[(identity.id, identity.version)] = package;
      return package.bundle;
    }
    final changeDefault = current == null || makeDefault;
    final retained = {...?current?.versions, identity.version};
    if (retained.length > 256) {
      throw const RemoteException(
        'driverInventory',
        'Too many installed versions of this driver.',
      );
    }
    await _activate(
      DriverInstallation(
        id: identity.id,
        active: changeDefault ? identity.version : current.active,
        previous: changeDefault ? current?.active : current.previous,
        enabled: current?.enabled ?? true,
        retained: Set.unmodifiable(retained),
      ),
      package,
    );
    return package.bundle;
  });

  Future<void> setEnabled(String id, bool enabled) => _serialize(() async {
    final current = _installed(id);
    if (current.enabled == enabled) {
      return;
    }
    final package = await _working(id, current.active);
    await _activate(
      DriverInstallation(
        id: id,
        active: current.active,
        previous: current.previous,
        enabled: enabled,
        retained: current.retained,
      ),
      package,
    );
  });

  Future<void> rollback(String id) => _serialize(() async {
    final current = _installed(id);
    final previous = current.previous;
    if (previous == null) {
      throw const RemoteException(
        'driverRollback',
        'No previous driver version is available.',
      );
    }
    final package = await _working(id, previous);
    await _activate(
      DriverInstallation(
        id: id,
        active: previous,
        previous: current.active,
        enabled: current.enabled,
        retained: current.retained,
      ),
      package,
    );
  });

  Future<DriverPackage> _working(String id, DriverVersion version) async =>
      await _validLocal(id, version) ??
      (throw const RemoteException(
        'driverUnavailable',
        'The installed driver is unavailable.',
      ));

  DriverInstallation _installed(String id) {
    _requireInitialized();
    return _inventory[id] ??
        (throw const RemoteException(
          'driverUnavailable',
          'The driver is not installed.',
        ));
  }

  Future<void> _activate(
    DriverInstallation record,
    DriverPackage package,
  ) async {
    final next = {..._inventory, record.id: record};
    await _storage.writeInventory(next.values);
    _inventory = next;
    _unavailable.remove(record.id);
    _installedPackages[(record.id, package.identity.version)] = package;
  }

  Future<(DriverInstallation, DriverPackage)?> _recover(
    DriverInstallation entry,
  ) async {
    final active = await _validLocal(entry.id, entry.active);
    if (active != null) {
      return (entry, active);
    }
    final alternatives = entry.retained.difference({
      entry.active,
      entry.previous,
    }).toList()..sort((a, b) => b.compareTo(a));
    for (final version in [
      if (entry.previous case final value?) value,
      ...alternatives,
    ]) {
      final fallback = await _validLocal(entry.id, version);
      if (fallback != null) {
        return (
          DriverInstallation(
            id: entry.id,
            active: version,
            enabled: entry.enabled,
            retained: entry.versions.difference({entry.active}),
          ),
          fallback,
        );
      }
    }
    return null;
  }

  Future<DriverPackage?> _validLocal(String id, DriverVersion version) async {
    try {
      final package = await _storage.read(id, version);
      return package != null && _supported(package) ? package : null;
    } on FormatException {
      return null;
    }
  }

  static bool supportsManifest(DriverManifest manifest) =>
      DriverVersionResolver.supports(manifest.runtime, DriverRuntime.version) &&
      DriverRuntime.operations.toSet().containsAll(manifest.runtime.operations);

  static bool _supported(DriverPackage package) =>
      supportsManifest(package.bundle.manifest);

  static void _checkCancellation(bool Function()? cancelled) {
    if (cancelled?.call() == true) {
      throw const RemoteException(
        'cancelled',
        'Driver installation cancelled.',
      );
    }
  }

  void _requireInitialized() {
    if (!_initialized) {
      throw StateError('Initialize the driver manager first.');
    }
  }

  Future<T> _serialize<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  static bool _sameIdentity(DriverIdentity a, DriverIdentity b) =>
      a.id == b.id && a.version == b.version && a.providerId == b.providerId;
}
