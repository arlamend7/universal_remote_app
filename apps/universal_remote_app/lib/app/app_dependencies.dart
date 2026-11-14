import 'package:remote_ui/remote_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';

import 'package:universal_remote_app/domains/connection/services/connection_controller.dart';
import 'package:universal_remote_app/domains/devices/services/saved_devices_controller.dart';
import 'package:universal_remote_app/domains/discovery/services/discovery_controller.dart';
import 'package:universal_remote_app/domains/settings/services/settings_controller.dart';

import '../domains/session/services/active_session.dart';

/// Application-owned instances, assembled once and injected through constructors.
final class AppDependencies {
  AppDependencies({
    required this.discovery,
    required this.savedDevices,
    required this.connection,
    required this.settings,
    required this.grids,
    required this.sleep,
    required this.providers,
    required this.inspectCertificate,
    this.session,
    this.disposeCredentials,
    this.drivers,
    this.checkDriverUpdates,
  });
  final DiscoveryController discovery;
  final SavedDevicesController savedDevices;
  final ConnectionController connection;
  final SettingsController settings;
  final ActiveSession? session;
  final DeviceGridsController grids;
  final DeviceSleepController sleep;
  final ProviderRegistry providers;
  final IntegrationService? drivers;
  final Future<void> Function()? checkDriverUpdates;
  final driverUpdatesAvailable = ValueNotifier<bool>(false);
  Future<void>? _driverCheck;

  Future<void> refreshDriverUpdates() {
    final check = checkDriverUpdates;
    if (check == null || _disposeFuture != null) {
      return Future.value();
    }
    return _driverCheck ??= _refreshDriverUpdates(check)
        .whenComplete(() => _driverCheck = null);
  }

  Future<void> _refreshDriverUpdates(Future<void> Function() check) async {
    await check();
    try {
      await updateDriverAvailability();
    } on Exception {
      // Keep the last known status if the cached catalog cannot be read.
    }
  }

  Future<void> updateDriverAvailability() async {
    final service = drivers;
    if (service == null || _disposeFuture != null) {
      return;
    }
    final catalog = await service.catalogs.cached();
    final available =
        catalog != null && await service.updates.hasUpdates(catalog);
    if (_disposeFuture == null) {
      driverUpdatesAvailable.value = available;
    }
  }

  final Future<PeerCertificate> Function(Uri) inspectCertificate;
  final void Function()? disposeCredentials;
  Future<List<String>> identifyAddress(
    String address,
    DiscoveryCancellation cancellation,
  ) async {
    final matches = await providers.identifyAddress(address, cancellation);
    final service = drivers;
    if (matches.isNotEmpty || service == null || cancellation.isCancelled) {
      return matches;
    }
    try {
      await service.refresh(providers);
    } on Exception {
      return matches;
    }
    if (cancellation.isCancelled) {
      return matches;
    }
    return providers.identifyAddress(address, cancellation);
  }

  Future<void>? _disposeFuture;
  Future<void> dispose() => _disposeFuture ??= _dispose();
  Future<void> _dispose() async {
    driverUpdatesAvailable.dispose();
    sleep.dispose();
    discovery.dispose();
    final sessionClosed = session?.close();
    await connection.dispose();
    await grids.dispose();
    await savedDevices.dispose();
    disposeCredentials?.call();
    settings.dispose();
    await sessionClosed;
  }
}
