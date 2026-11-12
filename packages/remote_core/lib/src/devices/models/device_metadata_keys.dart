/// Stable fields shared by device storage, integrations and presentation.
abstract final class DeviceMetadataKeys {
  static const trustedCertificateDer = 'trustedCertificateDer';
  static const discoveryIdentity = 'discoveryIdentity';
  static const verifiedPeerIdentity = 'verifiedPeerIdentity';

  /// An advertised hardware identifier (for example an mDNS TXT value) that
  /// only correlates sightings at the same endpoint; never a wake address.
  static const correlationIdentity = 'correlationIdentity';
  static const lastConnectedAt = 'lastConnectedAt';
  static const macAddressSource = 'macAddressSource';
  static const macAddress = 'macAddress';
  static const broadcastAddress = 'broadcastAddress';
  static const integrationId = 'driverIntegrationId';
  static const profileId = 'driverProfileId';
  static const packageSha256 = 'driverPackageSha256';
}
