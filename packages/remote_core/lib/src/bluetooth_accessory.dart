/// An accessory reported by the TV. Its identifier is scoped to that TV.
final class BluetoothAccessory {
  const BluetoothAccessory(this.id, this.name, {this.connected = false});

  final String id;
  final String name;
  final bool connected;
}
