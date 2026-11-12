import 'package:remote_core/remote_core.dart';

import '../catalog/catalog_integration.dart';
import '../catalog/integration_catalog.dart';
import 'installed_integration.dart';
import 'integration_catalog_repository.dart';
import 'integration_installer.dart';
import 'integration_package_source.dart';
import 'integration_update_report.dart';
import 'package_verifier.dart';
import 'update_schedule.dart';

/// Offline-first, hash-based updates of installed integrations.
///
/// The catalog is checked at most once per [interval] while the app runs.
/// A generation is downloaded only when its SHA-256 differs from the
/// installed one; `lastUpdatedAt` is informational and never compared.
final class IntegrationUpdateService {
  IntegrationUpdateService({
    required this.catalogs,
    required this.packages,
    required this.verifier,
    required this.installer,
    required this.schedule,
    this.interval = const Duration(hours: 24),
    this.retryAfterFailure = const Duration(hours: 48),
    this.allowDevelopment = false,
    bool Function(RuntimeRequirement requirement)? supportsRuntime,
    DateTime Function()? now,
  }) : _supportsRuntime = supportsRuntime ?? _any,
       _now = now ?? (() => DateTime.now().toUtc());

  final IntegrationCatalogRepository catalogs;
  final IntegrationPackageSource packages;
  final PackageVerifier verifier;
  final IntegrationInstaller installer;
  final UpdateSchedule schedule;
  final Duration interval, retryAfterFailure;
  final bool allowDevelopment;
  final bool Function(RuntimeRequirement requirement) _supportsRuntime;
  final DateTime Function() _now;

  /// Runs [checkNow] only when the persisted schedule says it is due.
  Future<IntegrationUpdateReport> checkIfDue() async {
    final due = await schedule.nextCheck();
    final now = _now();
    if (due != null && now.isBefore(due)) {
      return const IntegrationUpdateReport(checked: false);
    }
    // Schedule first so a crash or slow network cannot cause a check loop.
    await schedule.schedule(now.add(interval));
    try {
      return await checkNow();
    } catch (_) {
      await schedule.schedule(now.add(retryAfterFailure));
      rethrow;
    }
  }

  Future<IntegrationUpdateReport> checkNow() async {
    final installed = await installer.inventory();
    final catalog = await catalogs.refresh();
    final updated = <String, String>{};
    final staged = <String, String>{};
    final unchanged = <String>{};
    final skipped = <String, String>{};
    final failed = <String, String>{};
    for (final record in installed.values) {
      final entry = catalog.integration(record.integrationId);
      final reason = _skipReason(record, entry);
      if (reason == _unchanged) {
        unchanged.add(record.integrationId);
        continue;
      }
      if (reason != null) {
        skipped[record.integrationId] = reason;
        continue;
      }
      try {
        final result = await _install(entry!, catalog);
        final target = result.current == entry.sha256 ? updated : staged;
        target[record.integrationId] = entry.sha256;
      } on Object catch (error) {
        failed[record.integrationId] = _message(error);
      }
    }
    await installer.collectGarbage();
    return IntegrationUpdateReport(
      updated: updated,
      staged: staged,
      unchanged: unchanged,
      skipped: skipped,
      failed: failed,
    );
  }

  /// Installs a catalog integration that is not installed yet.
  Future<InstalledIntegration> installFromCatalog(
    CatalogIntegration entry,
    IntegrationCatalog catalog, {
    Future<void>? cancelled,
    void Function(int bytes)? onBytes,
  }) => _install(entry, catalog, cancelled: cancelled, onBytes: onBytes);

  String? _skipReason(InstalledIntegration record, CatalogIntegration? entry) {
    if (entry == null) {
      return 'No longer published in the catalog.';
    }
    if (entry.sha256 == record.current || entry.sha256 == record.staged) {
      return _unchanged;
    }
    if (entry.providerId != record.identity.providerId) {
      return 'The catalog changed the provider family.';
    }
    if (entry.sha256 == record.rejected) {
      return 'This generation was rolled back.';
    }
    if (!record.enabled) {
      return 'The integration is disabled.';
    }
    if (entry.development && !allowDevelopment) {
      return 'Development integrations are not allowed in this build.';
    }
    if (!_supportsRuntime(entry.runtime)) {
      return 'Requires a newer driver runtime.';
    }
    return null;
  }

  Future<InstalledIntegration> _install(
    CatalogIntegration entry,
    IntegrationCatalog catalog, {
    Future<void>? cancelled,
    void Function(int bytes)? onBytes,
  }) async {
    final bytes = await packages.fetch(
      entry,
      cancelled: cancelled,
      onBytes: onBytes,
    );
    if (bytes == null) {
      throw const RemoteException(
        'driverDownload',
        'The integration package is unavailable.',
      );
    }
    final (package, record) = await verifier.verify(
      entry,
      bytes,
      keyId: catalog.keyId,
      catalogRevision: catalog.revision,
      source: packages.name,
      now: _now(),
    );
    final result = await installer.install(package, record);
    if (result.current == entry.sha256) {
      await installer.pruneAssignments(entry.id, {
        for (final profile in package.manifest.profiles) profile.id,
      });
    }
    return result;
  }

  static const _unchanged = 'unchanged';

  static String _message(Object error) => switch (error) {
    RemoteException(:final message) => message,
    FormatException(:final message) => message,
    _ => 'The integration update failed.',
  };

  static bool _any(RuntimeRequirement _) => true;
}
