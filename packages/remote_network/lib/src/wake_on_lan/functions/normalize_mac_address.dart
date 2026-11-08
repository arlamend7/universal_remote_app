/// Canonical unicast hardware address, including unpadded OS neighbor entries.
String? normalizeMacAddress(String? address) {
  final parts = address?.trim().split(RegExp('[:-]')) ?? [];
  if (parts.length != 6 ||
      parts.any((part) => !RegExp(r'^[0-9a-fA-F]{1,2}$').hasMatch(part))) {
    return null;
  }
  final bytes = parts.map((part) => int.parse(part, radix: 16)).toList();
  if (bytes.every((byte) => byte == 0) || bytes.first.isOdd) {
    return null;
  }
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(':');
}
