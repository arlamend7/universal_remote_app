import 'package:remote_core/remote_core.dart';

import '../../commands/services/lg_command_channel.dart';

final class LgBluetoothAccessoryController {
  const LgBluetoothAccessoryController(this.channel);

  final LgCommandChannel channel;
  static const _service = 'com.webos.service.btaudiosrc';
  static final _address = RegExp(
    r'^(?:[0-9a-f]{2}:){5}[0-9a-f]{2}$',
    caseSensitive: false,
  );

  Future<List<BluetoothAccessory>> pairedDevices({Duration? timeout}) async {
    final response = await channel.send(
      RemoteCapability.bluetoothAccessories,
      '$_service/getPairedDevices',
      timeout: timeout,
    );
    final devices = response['devices'];
    if (devices is! List) {
      throw const RemoteException(
        'protocol',
        'The TV did not return a Bluetooth device list.',
      );
    }
    return devices
        .whereType<Map<String, dynamic>>()
        .map(_accessory)
        .whereType<BluetoothAccessory>()
        .toList();
  }

  BluetoothAccessory? _accessory(Map<String, dynamic> entry) {
    final id = entry['address'];
    final state = entry['state'];
    if (id is! String ||
        !_address.hasMatch(id) ||
        (state != 'connected' && state != 'disconnected')) {
      return null;
    }
    final name = entry['name'];
    return BluetoothAccessory(
      id.toUpperCase(),
      name is String && name.trim().isNotEmpty
          ? name.trim()
          : 'Bluetooth audio device',
      connected: state == 'connected',
    );
  }

  Future<void> toggle(String id) async {
    final devices = await pairedDevices();
    final target = devices
        .where((item) => item.id == id.toUpperCase())
        .firstOrNull;
    if (target == null) {
      throw const RemoteException(
        'accessory',
        'This accessory is no longer paired with the TV.',
      );
    }
    final method = target.connected ? 'disconnect' : 'connect';
    await channel.send(
      RemoteCapability.bluetoothAccessories,
      '$_service/$method',
      payload: {'address': target.id},
    );
  }
}
