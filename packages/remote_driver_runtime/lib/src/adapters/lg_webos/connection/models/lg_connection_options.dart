/// Session configuration is per device; legacy transport is always explicit.
final class LgConnectionOptions {
  const LgConnectionOptions({
    this.allowInsecure = false,
    this.trustedCertificateDer,
    this.macAddress,
    this.broadcastAddress = '255.255.255.255',
  });
  final bool allowInsecure;
  final String? trustedCertificateDer;
  final String? macAddress;
  final String broadcastAddress;
}
