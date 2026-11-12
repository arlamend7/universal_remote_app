/// Sends a Wake-on-LAN packet; injectable so tests never touch the network.
typedef WakeSender = Future<void> Function(String mac, String broadcast);
