import 'package:remote_ui/remote_ui.dart';

import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';
import 'package:remote_network/remote_network.dart';

import '../data/storage/adapters/native_secure_storage.dart';
import '../data/drivers/asset_driver_seed.dart';
import '../data/drivers/platform_driver_configuration.dart';
import '../domains/diagnostics/models/enums/app_log_level.dart';
import '../data/settings/screen_awake.dart';
import '../data/session/admob_rewarded_advertising.dart';
import '../data/storage/adapters/native_preferences_storage.dart';
import '../data/pairing/repositories/secure_credential_store.dart';
import '../data/pairing/repositories/session_credential_store.dart';
import '../data/network/services/platform_hardware_address_resolver.dart';
import '../data/devices/repositories/saved_device_repository.dart';
import '../data/dashboards/repositories/local_dashboard_repository.dart';
import '../data/network/services/multicast_network_access.dart';
import '../data/network/services/ios_bonjour.dart';
import '../data/network/functions/inspect_tv_certificate.dart';
import '../domains/storage/contracts/application_storage.dart';
import '../domains/diagnostics/services/diagnostic_logger.dart';
import '../domains/devices/services/saved_devices_controller.dart';
import '../domains/discovery/services/discovery_controller.dart';
import '../domains/settings/services/settings_controller.dart';
import '../domains/session/contracts/rewarded_advertising.dart';
import '../domains/session/services/active_session.dart';
import '../domains/connection/services/connection_controller.dart';
import 'app_dependencies.dart';

/// Composition root only: validation and platform operations live in adapters.
abstract final class AppBootstrap {
  static Future<AppDependencies> initialize({
    ApplicationStorage? storage,
    ApplicationStorage? credentialStorage,
    IntegrationService? driverService,
    Future<PeerCertificate> Function(Uri)? inspectCertificate,
    ProviderRegistry? registry,
    DiscoveryRegistry? discoveryProtocols,
    HardwareAddressResolver? hardwareAddressResolver,
    Future<void> Function()? acquireNetwork,
    Future<void> Function()? releaseNetwork,
    RewardedAdvertising? rewardedAdvertising,
    Duration Function()? sessionClock,
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
    final providers = registry ?? ProviderRegistry();
    final protocols = discoveryProtocols ?? _protocols();
    final logger = DiagnosticLogger();
    final ads = rewardedAdvertising ?? AdMobRewardedAdvertising.configured();
    final session = ads == null
        ? null
        : ActiveSession(preferences, ads, now: sessionClock);
    await session?.restore();
    final drivers = await _initializeDrivers(
      driverService,
      providers,
      credentials,
      logger,
    );
    final saved = SavedDevicesController(
      SavedDeviceRepository(preferences),
      credentials,
    );
    final discoveryManager = DiscoveryManager(
      protocols,
      const [],
      registeredIdentifiers: () =>
          providers.definitions.map((definition) => definition.identifier),
      savedProfiles: () => saved.registered.expand(
        (device) => device.profiles.map((profile) => profile.device),
      ),
    );
    final settings = SettingsController(
      preferences,
      logger,
      applyScreenAwake: Platform.isAndroid || Platform.isIOS
          ? ScreenAwake.setEnabled
          : null,
    );
    final network = MulticastNetworkAccess();
    await saved.initialize();
    await _migrateSavedDevices(drivers, saved);
    await settings.initialize(hasSavedDevices: saved.devices.value.isNotEmpty);
    final grids = DeviceGridsController(
      LocalDashboardRepository(preferences),
      deviceKey: (device) => saved.logicalDevice(device.id)?.id ?? device.id,
    );
    await grids.initialize();
    final connection = ConnectionController(
      providers,
      saved,
      logger,
      autoReconnect: () => settings.autoReconnect.value,
      removeDashboards: grids.removeForDevice,
      clearManagedCredentials: drivers?.clearCredentials,
      pinFirstCertificate: (device, code) async {
        final unpinned = providers
            .networkConfiguration(device)
            .certificate
            .isEmpty;
        if (!unpinned || !providers.canReviewCertificate(device, code)) {
          return null;
        }
        try {
          final certificate =
              await (inspectCertificate ?? inspectTvCertificate)(
                device.endpoints.first,
              );
          final trusted = providers.trustCertificate(
            device,
            certificate.derBase64,
          );
          await saved.updateExisting(trusted.id, (_) => trusted);
          return trusted;
        } on Object {
          return null;
        }
      },
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
        discoveryManager,
        acquireNetwork: acquireNetwork ?? network.acquire,
        releaseNetwork: releaseNetwork ?? network.release,
        logger: logger,
        refreshDriverCatalog: drivers == null
            ? null
            : () => drivers.refresh(providers),
      ),
      savedDevices: saved,
      settings: settings,
      session: session,
      grids: grids,
      connection: connection,
      disposeCredentials: sessionCredentials?.dispose,
      sleep: DeviceSleepController(connection),
      providers: providers,
      drivers: drivers,
      checkDriverUpdates: drivers == null
          ? null
          : () => _checkDriverUpdates(drivers, providers, logger),
      inspectCertificate: inspectCertificate ?? inspectTvCertificate,
    );
  }

  /// Rewrites version-based driver metadata on saved devices once; device
  /// IDs, credentials, certificate pins and dashboards are untouched.
  static Future<void> _migrateSavedDevices(
    IntegrationService? drivers,
    SavedDevicesController saved,
  ) async {
    if (drivers == null) {
      return;
    }
    for (final device in saved.devices.value) {
      final migrated = await drivers.migrateDevice(device);
      if (!identical(migrated, device)) {
        await saved.updateExisting(device.id, (_) => migrated);
      }
    }
  }

  static Future<void> _checkDriverUpdates(
    IntegrationService drivers,
    ProviderRegistry providers,
    DiagnosticLogger logger,
  ) async {
    try {
      await drivers.checkUpdates(providers);
    } on Exception {
      logger.record(AppLogLevel.warning, 'drivers.updateFailed');
    }
  }

  static Future<IntegrationService?> _initializeDrivers(
    IntegrationService? service,
    ProviderRegistry registry,
    CredentialStore credentials,
    DiagnosticLogger logger,
  ) async {
    try {
      final drivers =
          service ?? await PlatformDriverConfiguration.load(credentials);
      await drivers?.initialize(registry, seed: await _seed());
      return drivers;
    } on Exception {
      logger.record(AppLogLevel.warning, 'drivers.localInitializationFailed');
      return null;
    } on StateError {
      logger.record(AppLogLevel.warning, 'drivers.localInitializationFailed');
      return null;
    }
  }

  static Future<SeedBundle?> _seed() async {
    try {
      return await AssetDriverSeed.load(rootBundle);
    } on Exception {
      return null;
    }
  }

  static DiscoveryRegistry _protocols() => DiscoveryRegistry()
    ..register(DiscoveryProtocol.ssdp, const SsdpProtocol().search)
    ..register(
      DiscoveryProtocol.bonjour,
      Platform.isIOS ? IosBonjour().search : const MdnsDiscovery().search,
    );
}
