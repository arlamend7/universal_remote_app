/// Wake target reported by an authenticated device interface.
final class DeviceWakeAddress {
  const DeviceWakeAddress(this.macAddress, {this.broadcastAddress});
  final String macAddress;
  final String? broadcastAddress;
}
