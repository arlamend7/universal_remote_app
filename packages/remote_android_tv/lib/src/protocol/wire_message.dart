import 'dart:convert';
import 'dart:typed_data';

/// The varint and length-delimited fields used by Android TV Remote v2.
abstract final class WireMessage {
  static Uint8List encode(Map<int, Object> fields) {
    final bytes = BytesBuilder(copy: false);
    for (final entry in fields.entries) {
      final value = entry.value;
      if (value is int) {
        bytes.add(varint(entry.key << 3));
        bytes.add(varint(value));
        continue;
      }
      final data = value is String ? utf8.encode(value) : value as List<int>;
      bytes.add(varint((entry.key << 3) | 2));
      bytes.add(varint(data.length));
      bytes.add(data);
    }
    return bytes.takeBytes();
  }

  static Map<int, Object> decode(List<int> bytes) {
    final fields = <int, Object>{};
    var offset = 0;
    while (offset < bytes.length) {
      final (tag, start) = readVarint(bytes, offset);
      final field = tag >> 3;
      if (field == 0) {
        throw const FormatException('Invalid protobuf field.');
      }
      final (value, end) = _field(bytes, start, tag & 7);
      fields[field] = value;
      offset = end;
    }
    return fields;
  }

  static (Object, int) _field(List<int> bytes, int offset, int type) {
    if (type == 0) {
      return readVarint(bytes, offset);
    }
    final (length, start) = switch (type) {
      1 => (8, offset),
      2 => readVarint(bytes, offset),
      5 => (4, offset),
      _ => throw const FormatException('Unsupported protobuf wire type.'),
    };
    if (length < 0 || start + length > bytes.length) {
      throw const FormatException('Truncated protobuf field.');
    }
    return (bytes.sublist(start, start + length), start + length);
  }

  static List<int> varint(int value) {
    if (value < 0) {
      throw ArgumentError.value(value, 'value');
    }
    final bytes = <int>[];
    while (value >= 128) {
      bytes.add((value & 127) | 128);
      value >>= 7;
    }
    return [...bytes, value];
  }

  static (int, int) readVarint(List<int> bytes, int offset) {
    var value = 0;
    for (var shift = 0; shift < 64 && offset < bytes.length; shift += 7) {
      final byte = bytes[offset++];
      value |= (byte & 127) << shift;
      if (byte < 128) {
        return (value, offset);
      }
    }
    throw const FormatException('Invalid protobuf varint.');
  }
}
