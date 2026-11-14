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
    this.credentials,
  });

  final String providerId;
  final Map<String, Object?> json;
  final OfflineWakeEngine? engine;
  final EngineOperation? operation;
  final CredentialStore? credentials;

  String get _message =>
      (json['message'] as String?) ??
      'Configure the TV’s MAC address and enable network wake first.';

  @override
  bool canWakeDevice(RemoteDevice device) {
    if (device.providerId != providerId) {
      return false;
    }
    return _canWakeWithEngine(device) ||
        (json['kind'] != 'engine' || json['fallback'] == 'wake-on-lan') &&
            deviceWakeTarget(device) != null;
  }

  @override
  Future<void> wakeDevice(RemoteDevice device) async {
    if (!canWakeDevice(device)) {
      throw RemoteException('wakeUnavailable', _message);
    }
    if (_canWakeWithEngine(device)) {
      return engine!.wakeOffline(device, operation!, credentials: credentials!);
    }
    final target = deviceWakeTarget(device)!;
    await sendWakeOnLan(target.macAddress, broadcast: target.broadcastAddress!);
  }

  bool _canWakeWithEngine(RemoteDevice device) {
    final mapping = operation;
    return mapping != null &&
        credentials != null &&
        _hasCapability(device) &&
        engine?.canWakeOffline(device, mapping) == true;
  }

  bool _hasCapability(RemoteDevice device) {
    final required = json['requiresCapability'];
    return required == null ||
        device.capabilities.contains(parseRemoteCapability(required));
  }
}
