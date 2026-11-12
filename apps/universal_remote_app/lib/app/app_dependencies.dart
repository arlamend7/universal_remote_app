import 'package:remote_ui/remote_ui.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';

import 'package:universal_remote_app/domains/connection/services/connection_controller.dart';
import 'package:universal_remote_app/domains/devices/services/saved_devices_controller.dart';
import 'package:universal_remote_app/domains/discovery/services/discovery_controller.dart';
import 'package:universal_remote_app/domains/settings/services/settings_controller.dart';

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
    this.disposeCredentials,
    this.drivers,
    this.checkDriverUpdates,
  });
  final DiscoveryController discovery;
  final SavedDevicesController savedDevices;
  final ConnectionController connection;
  final SettingsController settings;
  final DeviceGridsController grids;
  final DeviceSleepController sleep;
  final ProviderRegistry providers;
  final IntegrationService? drivers;
  final Future<void> Function()? checkDriverUpdates;
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
    sleep.dispose();
    discovery.dispose();
    await connection.dispose();
    await grids.dispose();
    await savedDevices.dispose();
    disposeCredentials?.call();
    settings.dispose();
  }
}
