/// Network setup values returned by a provider for display in the app.
final class DeviceNetworkConfiguration {
  const DeviceNetworkConfiguration({
    this.address = '',
    this.certificate = '',
    this.mac = '',
    this.broadcast = '',
    this.legacy = false,
    this.allowInsecurePointer = false,
  });

  final String address, certificate, mac, broadcast;
  final bool legacy, allowInsecurePointer;
}
