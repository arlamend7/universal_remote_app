import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import '../../engines/contracts/engine_operation.dart';
import '../../engines/contracts/offline_wake_engine.dart';

/// `device.json#wake`: Wake-on-LAN from learned or configured addresses, or
/// an engine's standby wake operation.
final class DeclarativeWakeProvider implements DeviceWakeProvider {
  DeclarativeWakeProvider(
    this.providerId,
    this.json, {
    this.engine,
    this.operation,
  });

  final String providerId;
  final Map<String, Object?> json;
  final OfflineWakeEngine? engine;
  final EngineOperation? operation;

  String get _message =>
      (json['message'] as String?) ??
      'Configure the TV’s MAC address and enable network wake first.';

  @override
  bool canWakeDevice(RemoteDevice device) {
    if (device.providerId != providerId) {
      return false;
    }
    if (json['kind'] == 'engine') {
      return engine != null && operation != null && _hasCapability(device);
    }
    return deviceWakeTarget(device) != null;
  }

  @override
  Future<void> wakeDevice(RemoteDevice device) async {
    if (!canWakeDevice(device)) {
      throw RemoteException('wakeUnavailable', _message);
    }
    if (json['kind'] == 'engine') {
      return engine!.wakeOffline(device, operation!);
    }
    final target = deviceWakeTarget(device)!;
    await sendWakeOnLan(target.macAddress, broadcast: target.broadcastAddress!);
  }

  bool _hasCapability(RemoteDevice device) {
    final required = json['requiresCapability'];
    return required == null ||
        device.capabilities.contains(parseRemoteCapability(required));
  }
}
