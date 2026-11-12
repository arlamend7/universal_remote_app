/// Saved-device metadata written by the integration runtime.
abstract final class IntegrationMetadataKeys {
  static const integrationId = 'driverIntegrationId';
  static const profileId = 'driverProfileId';
  static const packageSha256 = 'driverPackageSha256';

  /// Keys written by the retired version-based driver manager.
  static const legacy = {
    'managedDriverId',
    'managedDriverVersion',
    'managedDriverProfile',
    'managedDriverProfileVersion',
    'managedDriverPinnedVersion',
  };
}
