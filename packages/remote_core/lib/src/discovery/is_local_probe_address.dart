import 'dart:io';

bool isLocalProbeAddress(String host) {
  final address = InternetAddress.tryParse(host);
  if (address == null) {
    return false;
  }
  final bytes = address.rawAddress;
  if (address.type == InternetAddressType.IPv6) {
    return (bytes.first & 0xfe) == 0xfc;
  }
  final [first, second, _, _] = bytes;
  return first == 10 ||
      (first == 172 && second >= 16 && second <= 31) ||
      (first == 192 && second == 168) ||
      (first == 169 && second == 254);
}
