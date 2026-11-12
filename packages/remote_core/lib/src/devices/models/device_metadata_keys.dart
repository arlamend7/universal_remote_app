/// Stable fields shared by device storage, integrations and presentation.
abstract final class DeviceMetadataKeys {
  static const trustedCertificateDer = 'trustedCertificateDer';
  static const discoveryIdentity = 'discoveryIdentity';
  static const verifiedPeerIdentity = 'verifiedPeerIdentity';
  static const lastConnectedAt = 'lastConnectedAt';
  static const macAddressSource = 'macAddressSource';
  static const macAddress = 'macAddress';
  static const broadcastAddress = 'broadcastAddress';
  static const integrationId = 'driverIntegrationId';
  static const profileId = 'driverProfileId';
  static const packageSha256 = 'driverPackageSha256';
}
