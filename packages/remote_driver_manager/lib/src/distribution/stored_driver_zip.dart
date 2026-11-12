import 'dart:convert';
import 'dart:typed_data';

/// Reads the bounded ZIP subset emitted by the driver package builder.
final class StoredDriverZip {
  StoredDriverZip(this._bytes) : _data = ByteData.sublistView(_bytes);

  /// Entry names permitted in a schema-2 integration package.
  static final _paths = RegExp(
    r'^(?:manifest|discovery|connection|identification|capabilities|mappings|workflows/[a-z][a-z0-9_-]{0,63})\.json$',
  );

  final Uint8List _bytes;
  final ByteData _data;

  Map<String, String> read() {
    final end = _bytes.length - 22;
    if (end < 0 ||
        _u32(end) != 0x06054b50 ||
        _u32(end + 4) != 0 ||
        _u16(end + 20) != 0) {
      throw _invalid;
    }
    final count = _u16(end + 10);
    final central = _u32(end + 16);
    final centralSize = _u32(end + 12);
    if (count < 3 ||
        count > _maximumFiles ||
        _u16(end + 8) != count ||
        central + centralSize != end) {
      throw _invalid;
    }
    final files = <String, String>{};
    var cursor = central;
    var local = 0;
    for (var index = 0; index < count; index++) {
      final entry = _entry(cursor, end, local, central);
      if (files.containsKey(entry.path)) {
        throw _invalid;
      }
      files[entry.path] = entry.content;
      cursor = entry.centralEnd;
      local = entry.localEnd;
    }
    if (cursor != end || local != central) {
      throw _invalid;
    }
    return files;
  }

  ({String path, String content, int centralEnd, int localEnd}) _entry(
    int cursor,
    int end,
    int local,
    int central,
  ) {
    if (cursor + 46 > end ||
        _u32(cursor) != 0x02014b50 ||
        _u32(cursor + 8) != 0 ||
        _u16(cursor + 30) != 0 ||
        _u16(cursor + 32) != 0 ||
        _u16(cursor + 34) != 0 ||
        _u32(cursor + 38) >> 16 != 0x81a4 ||
        _u32(cursor + 42) != local) {
      throw _invalid;
    }
    final nameLength = _u16(cursor + 28);
    final length = _u32(cursor + 24);
    final centralEnd = cursor + 46 + nameLength;
    final content = local + 30 + nameLength;
    final localEnd = content + length;
    if (nameLength < 1 ||
        nameLength > 128 ||
        centralEnd > end ||
        localEnd > central ||
        length > _maximumFileBytes ||
        _u32(cursor + 20) != length ||
        _u32(local) != 0x04034b50 ||
        _u32(local + 6) != 0 ||
        _u32(local + 14) != _u32(cursor + 16) ||
        _u32(local + 18) != length ||
        _u32(local + 22) != length ||
        _u16(local + 26) != nameLength ||
        _u16(local + 28) != 0) {
      throw _invalid;
    }
    final path = ascii.decode(_bytes.sublist(cursor + 46, centralEnd));
    final localPath = ascii.decode(_bytes.sublist(local + 30, content));
    if (path != localPath || _paths.firstMatch(path)?.end != path.length) {
      throw _invalid;
    }
    return (
      path: path,
      content: utf8.decode(_bytes.sublist(content, localEnd)),
      centralEnd: centralEnd,
      localEnd: localEnd,
    );
  }

  int _u16(int offset) => _data.getUint16(offset, Endian.little);
  int _u32(int offset) => _data.getUint32(offset, Endian.little);

  static const _maximumFiles = 64;
  static const _maximumFileBytes = 256 * 1024;
  static const _invalid = FormatException('Invalid or unsupported driver ZIP.');
}
