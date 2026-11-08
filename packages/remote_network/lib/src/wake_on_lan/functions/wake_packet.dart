import 'dart:typed_data';

import 'normalize_mac_address.dart';

/// Standard magic packet, with a MAC supplied by the user or reliable discovery.
Uint8List wakePacket(String mac) {
  final normalized = normalizeMacAddress(mac);
  if (normalized == null) {
    throw ArgumentError('A valid unicast MAC address is required.');
  }
  final octets = normalized
      .split(':')
      .map((part) => int.parse(part, radix: 16))
      .toList();
  return Uint8List.fromList([
    ...List.filled(6, 255),
    for (var i = 0; i < 16; i++) ...octets,
  ]);
}
