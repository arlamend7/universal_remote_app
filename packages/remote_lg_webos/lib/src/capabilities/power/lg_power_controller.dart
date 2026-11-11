import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_lg_webos/src/commands/services/lg_command_channel.dart';
import 'package:remote_lg_webos/src/connection/models/lg_connection_options.dart';
import 'package:remote_network/remote_network.dart';

final class LgPowerController {
  LgPowerController(this.channel, this.options, {this.bindings});
  final DriverBindings? bindings;
  final LgConnectionOptions options;
  final LgCommandChannel channel;
  bool get canWake => normalizeMacAddress(options.macAddress) != null;
  Future<void> powerOff() async {
    const path = 'system/turnOff';
    await channel.send(
      RemoteCapability.power,
      bindings?.select('power-off', path) ?? path,
    );
  }

  Future<void> wake() async {
    final mac = normalizeMacAddress(options.macAddress);
    if (mac == null) {
      throw const RemoteException(
        'wakeUnavailable',
        'Configure a verified MAC address and enable network wake on the TV first.',
      );
    }
    await sendWakeOnLan(mac, broadcast: options.broadcastAddress);
  }
}
