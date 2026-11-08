import 'package:remote_ui/remote_ui.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

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
    required this.canWakeDevice,
    required this.inspectCertificate,
    this.importLegacyPreferences,
    this.disposeCredentials,
  });
  final DiscoveryController discovery;
  final SavedDevicesController savedDevices;
  final ConnectionController connection;
  final SettingsController settings;
  final DeviceGridsController grids;
  final DeviceSleepController sleep;
  final bool Function(RemoteDevice) canWakeDevice;
  final Future<PeerCertificate> Function(Uri) inspectCertificate;
  final Future<void> Function()? importLegacyPreferences;
  final void Function()? disposeCredentials;
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
