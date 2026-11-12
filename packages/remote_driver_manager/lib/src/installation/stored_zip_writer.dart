import 'dart:convert';
import 'dart:typed_data';

/// Writes the deterministic, uncompressed ZIP subset the publisher emits
/// (used for local development packages and tests).
Uint8List storedZip(Map<String, String> files) {
  final local = BytesBuilder();
  final central = BytesBuilder();
  final names = files.keys.toList()..sort();
  for (final name in names) {
    final path = ascii.encode(name);
    final content = utf8.encode(files[name]!);
    final crc = _crc32(content);
    final offset = local.length;
    local
      ..add(_u32(0x04034b50))
      ..add(_u16(20))
      ..add(_u32(0))
      ..add(_u16(0))
      ..add(_u16(0x21))
      ..add(_u32(crc))
      ..add(_u32(content.length))
      ..add(_u32(content.length))
      ..add(_u16(path.length))
      ..add(_u16(0))
      ..add(path)
      ..add(content);
    central
      ..add(_u32(0x02014b50))
      ..add(_u16(0x0314))
      ..add(_u16(20))
      ..add(_u32(0))
      ..add(_u16(0))
      ..add(_u16(0x21))
      ..add(_u32(crc))
      ..add(_u32(content.length))
      ..add(_u32(content.length))
      ..add(_u16(path.length))
      ..add(_u16(0))
      ..add(_u16(0))
      ..add(_u16(0))
      ..add(_u16(0))
      ..add(_u32(0x81a4 << 16))
      ..add(_u32(offset))
      ..add(path);
  }
  final centralOffset = local.length;
  final directory = central.takeBytes();
  return (BytesBuilder()
        ..add(local.takeBytes())
        ..add(directory)
        ..add(_u32(0x06054b50))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(names.length))
        ..add(_u16(names.length))
        ..add(_u32(directory.length))
        ..add(_u32(centralOffset))
        ..add(_u16(0)))
      .takeBytes();
}

List<int> _u16(int value) =>
    (ByteData(2)..setUint16(0, value, Endian.little)).buffer.asUint8List();

List<int> _u32(int value) =>
    (ByteData(4)..setUint32(0, value, Endian.little)).buffer.asUint8List();

int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc >> 1) ^ (0xedb88320 & -(crc & 1));
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}
