import 'package:remote_ui/remote_ui.dart';

import 'dart:io';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/widgets.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_android_tv/remote_android_tv.dart';
import 'package:remote_lg_webos/remote_lg_webos.dart';
import 'package:remote_network/remote_network.dart';
import 'package:remote_roku/remote_roku.dart';

import '../data/storage/adapters/native_secure_storage.dart';
import '../data/storage/adapters/native_preferences_storage.dart';
import '../data/pairing/repositories/secure_credential_store.dart';
import '../data/pairing/repositories/session_credential_store.dart';
import '../data/network/services/platform_hardware_address_resolver.dart';
import '../data/devices/repositories/saved_device_repository.dart';
import '../data/devices/mappers/saved_device_mapper.dart';
import '../data/dashboards/repositories/local_dashboard_repository.dart';
import '../data/network/services/multicast_network_access.dart';
import '../data/network/functions/inspect_tv_certificate.dart';
import '../domains/storage/contracts/application_storage.dart';
import '../domains/diagnostics/services/diagnostic_logger.dart';
import '../domains/devices/services/saved_devices_controller.dart';
import '../domains/discovery/services/discovery_controller.dart';
import '../domains/settings/services/settings_controller.dart';
import '../domains/connection/services/connection_controller.dart';
import 'app_dependencies.dart';

/// Composition root only: validation and platform operations live in adapters.
abstract final class AppBootstrap {
  static Future<AppDependencies> initialize({
    ApplicationStorage? storage,
    ApplicationStorage? credentialStorage,
    Future<PeerCertificate> Function(Uri)? inspectCertificate,
    ProviderRegistry? registry,
    HardwareAddressResolver? hardwareAddressResolver,
    Future<void> Function()? acquireNetwork,
    Future<void> Function()? releaseNetwork,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    final preferences = storage ?? NativePreferencesStorage();
    final protectedStorage =
        credentialStorage ?? storage ?? NativeSecureStorage();
    final protectedCredentials = SecureCredentialStore(protectedStorage);
    final sessionCredentials = Platform.isMacOS
        ? SessionCredentialStore(protectedCredentials)
        : null;
    final CredentialStore credentials =
        sessionCredentials ?? protectedCredentials;
    final provider = LgWebOsProvider(credentials: credentials);
    final providers =
        registry ??
        (ProviderRegistry()
          ..register(provider)
          ..register(AndroidTvProvider(credentials: credentials)));
    if (registry == null &&
        !kReleaseMode &&
        const bool.fromEnvironment('ENABLE_ROKU_ECP')) {
      providers.register(const RokuProvider());
    }
    final logger = DiagnosticLogger();
    final saved = SavedDevicesController(
      SavedDeviceRepository(
        preferences,
        mapper: SavedDeviceMapper(categoryForProvider: providers.categoryFor),
      ),
      credentials,
    );
    final settings = SettingsController(preferences, logger);
    final network = MulticastNetworkAccess();
    await saved.initialize();
    await settings.initialize();
    final grids = DeviceGridsController(LocalDashboardRepository(preferences));
    await grids.initialize();
    final connection = ConnectionController(
      providers,
      saved,
      logger,
      wakeLearner: DeviceWakeLearner(
        lookup: saved.byId,
        update: saved.updateExisting,
        registry: providers,
        resolver: hardwareAddressResolver ?? PlatformHardwareAddressResolver(),
        normalizeMacAddress: normalizeMacAddress,
      ),
    );
    return AppDependencies(
      discovery: DiscoveryController(
        providers,
        acquireNetwork: acquireNetwork ?? network.acquire,
        releaseNetwork: releaseNetwork ?? network.release,
      ),
      savedDevices: saved,
      settings: settings,
      grids: grids,
      connection: connection,
      disposeCredentials: sessionCredentials?.dispose,
      sleep: DeviceSleepController(connection),
      providers: providers,
      inspectCertificate: inspectCertificate ?? inspectTvCertificate,
    );
  }
}
