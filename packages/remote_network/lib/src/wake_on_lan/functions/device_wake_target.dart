import 'package:remote_core/remote_core.dart';

import 'normalize_mac_address.dart';

/// Resolves the saved target, using the supplied default for its broadcast.
DeviceWakeAddress? deviceWakeTarget(
  RemoteDevice device, {
  String? defaultBroadcast,
}) {
  final mac = normalizeMacAddress(
    device.metadata[DeviceMetadataKeys.macAddress],
  );
  if (mac == null) {
    return null;
  }
  return DeviceWakeAddress(
    mac,
    broadcastAddress:
        device.metadata[DeviceMetadataKeys.broadcastAddress] ??
        defaultBroadcast ??
        '255.255.255.255',
  );
}
