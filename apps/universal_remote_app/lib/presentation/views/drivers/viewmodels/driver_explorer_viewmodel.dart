import 'package:flutter/foundation.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';

import '../models/driver_integration_summary.dart';
import '../models/driver_provider_summary.dart';

/// Reads only the verified cached catalog and the local inventory; opening
/// the Explorer never downloads packages or contacts the repository.
final class DriverExplorerViewModel {
  DriverExplorerViewModel(this.drivers);

  final IntegrationService? drivers;
  final loading = ValueNotifier(true);
  final failed = ValueNotifier(false);
  final providers = ValueNotifier<List<DriverProviderSummary>>(const []);
  final checkedAt = ValueNotifier<DateTime?>(null);

  Future<void> load() async {
    final service = drivers;
    try {
      if (service == null) {
        return;
      }
      final catalog = await service.catalogs.cached();
      final inventory = await service.installer.inventory();
      checkedAt.value = await service.catalogs.lastChecked();
      providers.value = _group(catalog, inventory, service.allowDevelopment);
    } on FormatException {
      failed.value = true;
    } finally {
      loading.value = false;
    }
  }

  static List<DriverProviderSummary> _group(
    IntegrationCatalog? catalog,
    Map<String, InstalledIntegration> inventory,
    bool allowDevelopment,
  ) {
    final families = <String, List<DriverIntegrationSummary>>{};
    for (final entry in catalog?.integrations ?? const <CatalogIntegration>[]) {
      if (entry.development && !allowDevelopment) {
        continue;
      }
      families
          .putIfAbsent(entry.providerId, () => [])
          .add(DriverIntegrationSummary(entry, inventory[entry.id]));
    }
    return [
      for (final entry in families.entries)
        DriverProviderSummary(
          entry.key,
          entry.value..sort((a, b) => b.entry.priority - a.entry.priority),
        ),
    ];
  }

  void dispose() {
    loading.dispose();
    failed.dispose();
    providers.dispose();
    checkedAt.dispose();
  }
}
