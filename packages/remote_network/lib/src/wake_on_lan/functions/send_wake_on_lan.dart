import 'dart:io';

import 'wake_packet.dart';

Future<void> sendWakeOnLan(
  String mac, {
  String broadcast = '255.255.255.255',
}) async {
  final bytes = wakePacket(mac);
  final address = InternetAddress.tryParse(broadcast);
  if (address == null || address.type != InternetAddressType.IPv4) {
    throw ArgumentError('An IPv4 broadcast address is required.');
  }
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  try {
    socket.broadcastEnabled = true;
    if (socket.send(bytes, address, 9) != bytes.length) {
      throw const SocketException('Wake packet was not sent.');
    }
  } finally {
    socket.close();
  }
}
