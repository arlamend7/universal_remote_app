import 'dart:async';
import 'dart:io';

import 'package:remote_core/remote_core.dart';

import 'device_assignment.dart';
import 'installed_generation.dart';
import 'installed_integration.dart';
import 'integration_inventory.dart';
import 'integration_object_store.dart';
import 'integration_package.dart';
import 'verified_object.dart';

/// Installs verified generations atomically, keeps the previous generation
/// for rollback and never swaps the package under an active session.
final class IntegrationInstaller {
  IntegrationInstaller(
    this.root, {
    bool Function(String integrationId)? inUse,
    DateTime Function()? now,
  }) : _objects = IntegrationObjectStore(root),
       _inventory = IntegrationInventory(root),
       _inUse = inUse ?? _never,
       _now = now ?? _utcNow;

  final Directory root;
  final IntegrationObjectStore _objects;
  final IntegrationInventory _inventory;
  final bool Function(String integrationId) _inUse;
  final DateTime Function() _now;
  Future<void> _tail = Future.value();

  Future<Map<String, InstalledIntegration>> inventory() => _inventory.read();

  Future<InstalledIntegration?> installation(String integrationId) async =>
      (await _inventory.read())[integrationId];

  /// Stores [package] and activates it, or stages it while it is in use.
  Future<InstalledIntegration> install(
    IntegrationPackage package,
    VerifiedObject record,
  ) => _serialized(() async {
    await _objects.write(package, record);
    return _update(record.identity, (existing) {
      final now = _now();
      final base = existing ?? InstalledIntegration(identity: record.identity);
      if (base.current == record.sha256) {
        return base.copyWith(clearStaged: base.staged == record.sha256);
      }
      if (base.current != null && _inUse(base.integrationId)) {
        return base.copyWith(staged: record.sha256);
      }
      return _activate(base, record, now);
    });
  });

  /// Promotes a staged generation once no session uses the integration.
  Future<InstalledIntegration?> activateStaged(String integrationId) =>
      _serialized(() async {
        final record = (await _inventory.read())[integrationId];
        final staged = record?.staged;
        if (record == null || staged == null || _inUse(integrationId)) {
          return record;
        }
        final loaded = await _objects.read(staged);
        if (loaded == null) {
          return _update(
            record.identity,
            (current) => current!.copyWith(clearStaged: true),
          );
        }
        return _update(
          record.identity,
          (current) => _activate(current!, loaded.$2, _now()),
        );
      });

  /// Restores the previous verified generation and refuses to auto-update
  /// back to the generation that was rolled back.
  Future<InstalledIntegration> rollback(String integrationId) =>
      _serialized(() async {
        final record = (await _inventory.read())[integrationId];
        final previous = record?.previous;
        if (record == null || previous == null) {
          throw const RemoteException(
            'rollbackUnavailable',
            'No previous verified driver package is installed.',
          );
        }
        final loaded = await _intact(previous);
        if (loaded == null) {
          throw const RemoteException(
            'rollbackUnavailable',
            'The previous driver package failed verification.',
          );
        }
        return _update(
          record.identity,
          (current) => current!.copyWith(
            current: previous,
            previous: current.current,
            rejected: current.current,
            lastUpdatedAt: loaded.record.lastUpdatedAt,
            updatedAt: _now(),
            clearStaged: true,
          ),
        );
      });

  /// Loads the active generation, falling back to the previous one if the
  /// active object is missing or corrupt.
  Future<InstalledGeneration?> load(String integrationId) async {
    final record = (await _inventory.read())[integrationId];
    if (record == null || !record.enabled) {
      return null;
    }
    final current = record.current;
    final active = current == null ? null : await _intact(current);
    if (active != null) {
      return active;
    }
    final previous = record.previous;
    final fallback = previous == null ? null : await _intact(previous);
    if (fallback == null) {
      return null;
    }
    await _serialized(
      () => _update(
        record.identity,
        (value) => value!.copyWith(
          current: previous,
          lastUpdatedAt: fallback.record.lastUpdatedAt,
          clearPrevious: true,
        ),
      ),
    );
    return InstalledGeneration(
      fallback.package,
      fallback.record,
      recovered: true,
    );
  }

  Future<InstalledIntegration> setEnabled(String integrationId, bool enabled) =>
      _serialized(() async {
        final record = (await _inventory.read())[integrationId];
        if (record == null) {
          throw const RemoteException(
            'driverMissing',
            'The driver integration is not installed.',
          );
        }
        return _update(
          record.identity,
          (current) => current!.copyWith(enabled: enabled),
        );
      });

  /// Records the profile selected for [deviceId] and removes the device from
  /// every other integration.
  Future<void> assign(
    IntegrationIdentity identity,
    String deviceId,
    String profileId,
  ) => _serialized(() async {
    final records = await _inventory.read();
    final assignment = DeviceAssignment(
      profileId: profileId,
      assignedAt: _now(),
    );
    final updated = {
      for (final entry in records.entries)
        entry.key: _withoutDevice(entry.value, deviceId),
    };
    final target =
        updated[identity.integrationId] ??
        InstalledIntegration(identity: identity);
    updated[identity.integrationId] = target.copyWith(
      assignments: {...target.assignments, deviceId: assignment},
    );
    await _inventory.write(updated.values);
  });

  Future<void> unassign(String deviceId) => _serialized(() async {
    final records = await _inventory.read();
    await _inventory.write(
      records.values.map((record) => _withoutDevice(record, deviceId)),
    );
  });

  /// Removes assignments to profiles the active generation no longer has.
  Future<void> pruneAssignments(String integrationId, Set<String> profileIds) =>
      _serialized(() async {
        final record = (await _inventory.read())[integrationId];
        if (record == null) {
          return;
        }
        await _update(
          record.identity,
          (current) => current!.copyWith(
            assignments: {
              for (final entry in current.assignments.entries)
                if (profileIds.contains(entry.value.profileId))
                  entry.key: entry.value,
            },
          ),
        );
      });

  /// Deletes objects no inventory record needs for activation or rollback.
  Future<Set<String>> collectGarbage() => _serialized(() async {
    final records = await _inventory.read();
    final referenced = {
      for (final record in records.values) ...record.referencedHashes,
    };
    final removed = (await _objects.hashes()).difference(referenced);
    for (final hash in removed) {
      await _objects.delete(hash);
    }
    return removed;
  });

  Future<InstalledGeneration?> _intact(String sha256) async {
    try {
      final loaded = await _objects.read(sha256);
      return loaded == null ? null : InstalledGeneration(loaded.$1, loaded.$2);
    } on FormatException {
      return null;
    }
  }

  InstalledIntegration _activate(
    InstalledIntegration base,
    VerifiedObject record,
    DateTime now,
  ) => base.copyWith(
    current: record.sha256,
    previous: base.current,
    installedAt: base.installedAt ?? now,
    updatedAt: now,
    lastUpdatedAt: record.lastUpdatedAt,
    clearPrevious: base.current == null,
    clearStaged: true,
    clearRejected: base.rejected == record.sha256,
  );

  static InstalledIntegration _withoutDevice(
    InstalledIntegration record,
    String deviceId,
  ) {
    if (!record.assignments.containsKey(deviceId)) {
      return record;
    }
    return record.copyWith(
      assignments: {...record.assignments}..remove(deviceId),
    );
  }

  Future<InstalledIntegration> _update(
    IntegrationIdentity identity,
    InstalledIntegration Function(InstalledIntegration? existing) change,
  ) async {
    final records = await _inventory.read();
    final existing = records[identity.integrationId];
    if (existing != null && existing.identity != identity) {
      throw const RemoteException(
        'driverConflict',
        'An integration cannot change its provider family.',
      );
    }
    final next = change(existing);
    records[identity.integrationId] = next;
    await _inventory.write(records.values);
    return next;
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  static bool _never(String _) => false;
  static DateTime _utcNow() => DateTime.now().toUtc();
}
