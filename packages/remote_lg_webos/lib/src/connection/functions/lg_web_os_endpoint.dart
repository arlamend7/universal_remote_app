import 'dart:io';

/// TLS is the default. Legacy port 3000 is an explicit caller choice.
Uri lgWebOsEndpoint(String address, {bool secure = true}) {
  final parsed = InternetAddress.tryParse(address.trim());
  if (parsed == null ||
      parsed.isMulticast ||
      parsed.isLoopback ||
      parsed.address == '0.0.0.0' ||
      parsed.address == '::' ||
      parsed.address == '255.255.255.255') {
    throw const FormatException('Enter the TV’s numeric local IP address.');
  }
  return Uri(
    scheme: secure ? 'wss' : 'ws',
    host: parsed.address,
    port: secure ? 3001 : 3000,
  );
}
