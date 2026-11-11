import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';
import 'package:remote_network/remote_network.dart';

import '../distribution/driver_catalog.dart';
import '../distribution/driver_release.dart';
import '../resolution/driver_candidate.dart';
import '../resolution/driver_resolver.dart';
import 'driver_installation.dart';
import 'driver_manager.dart';
import 'driver_package_storage.dart';

/// One persisted update window across launches, resumes and retries.
final class DriverUpdateService {
  DriverUpdateService(this._manager, this._storage, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DriverManager _manager;
  final DriverPackageStorage _storage;
  final DateTime Function() _now;
  final _resolver = DriverResolver(
    runtimeVersion: DriverRuntime.version,
    operations: DriverRuntime.operations,
  );
  Future<void>? _running;

  Future<void> check(
    Iterable<RemoteDevice> devices,
    Future<DriverCatalog> Function() refresh,
  ) {
    final active = _running;
    if (active != null) {
      return active;
    }
    final check = _check(devices.toList(), refresh).whenComplete(() {
      _running = null;
    });
    return _running = check;
  }

  Future<void> _check(
    List<RemoteDevice> devices,
    Future<DriverCatalog> Function() refresh,
  ) async {
    final installed = _manager.inventory.values.where((entry) => entry.enabled);
    if (devices.isEmpty || installed.isEmpty) {
      return;
    }
    final now = _now().toUtc();
    final next = await _storage.nextUpdate();
    if (next != null && now.isBefore(next)) {
      return;
    }
    await _storage.scheduleUpdate(now.add(const Duration(hours: 24)));
    try {
      final catalog = await refresh();
      for (final record in installed) {
        await _update(record, devices, catalog);
      }
    } on Exception {
      await _storage.scheduleUpdate(now.add(const Duration(hours: 48)));
      rethrow;
    }
  }

  Future<void> _update(
    DriverInstallation record,
    List<RemoteDevice> devices,
    DriverCatalog catalog,
  ) async {
    final bundle = _manager.active(record.id);
    if (bundle == null) {
      return;
    }
    final provider = bundle.manifest.identity.providerId;
    final evidence = devices
        .where((device) => device.providerId == provider)
        .map(_evidence)
        .toList();
    if (evidence.isEmpty) {
      return;
    }
    final eligible =
        catalog.releases
            .where(
              (release) =>
                  _compatibleRelease(release, record, provider, evidence),
            )
            .toList()
          ..sort(
            (a, b) => b.manifest.identity.version.compareTo(
              a.manifest.identity.version,
            ),
          );
    final release = eligible.firstOrNull;
    if (release == null ||
        _manager.inventory[record.id]?.active != record.active) {
      return;
    }
    await _manager.install(
      release.manifest.identity,
      expectedActive: record.active,
    );
  }

  bool _compatibleRelease(
    DriverRelease release,
    DriverInstallation record,
    String provider,
    List<DriverDeviceEvidence> evidence,
  ) {
    final id = release.manifest.identity;
    final previous = record.previous;
    if (release.development ||
        id.id != record.id ||
        id.providerId != provider ||
        id.version.compareTo(record.active) <= 0 ||
        (previous != null && id.version.compareTo(previous) <= 0)) {
      return false;
    }
    final candidate = DriverCandidate(release.manifest);
    return evidence.every(
      (device) => _resolver.resolve(device, [candidate]).selected != null,
    );
  }

  static DriverDeviceEvidence _evidence(RemoteDevice device) =>
      DriverDeviceEvidence.fromDevice(
        device,
        osVersion: device.metadata['osVersion'],
        firmwareVersion: device.metadata['firmwareVersion'],
      );
}
