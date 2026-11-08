import 'dart:io';

/// Directed broadcast for a valid IPv4 host/subnet. Point-to-point links have none.
String? ipv4BroadcastAddress(String host, String? subnetMask) {
  final address = _ipv4Number(host), mask = _ipv4Number(subnetMask);
  if (address == null || mask == null || mask == 0 || address >> 24 >= 224) {
    return null;
  }
  final hostMask = mask ^ 0xffffffff;
  if (hostMask < 3 || (hostMask & (hostMask + 1)) != 0) {
    return null;
  }
  final network = address & mask;
  final broadcast = network | hostMask;
  if (address == network || address == broadcast) {
    return null;
  }
  return [24, 16, 8, 0].map((shift) => (broadcast >> shift) & 255).join('.');
}

int? _ipv4Number(String? value) {
  final address = value == null ? null : InternetAddress.tryParse(value);
  if (address == null || address.type != InternetAddressType.IPv4) {
    return null;
  }
  return address.rawAddress.fold<int>(
    0,
    (number, octet) => (number << 8) | octet,
  );
}
