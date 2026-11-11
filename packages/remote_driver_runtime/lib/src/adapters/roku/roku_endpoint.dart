import 'dart:io';

bool isRokuLanAddress(InternetAddress? ip) {
  if (ip == null || ip.type != InternetAddressType.IPv4) {
    return false;
  }
  final [first, second, _, _] = ip.rawAddress;
  return first == 10 ||
      (first == 192 && second == 168) ||
      (first == 172 && second >= 16 && second <= 31) ||
      (first == 169 && second == 254);
}

Uri rokuEndpoint(String host) => Uri(scheme: 'http', host: host, port: 8060);
