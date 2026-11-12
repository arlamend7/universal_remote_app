import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'wire_message.dart';

final class FramedSocket {
  /// A peer reset also completes [SecureSocket.done] with an error. Reads
  /// report it through [next] and writes through `flush`, so `done` itself is
  /// observed here instead of escaping as an unhandled error.
  FramedSocket(this.socket) {
    unawaited(socket.done.then<void>((_) {}, onError: (Object _) {}));
  }

  final SecureSocket socket;
  late final _messages = StreamIterator(_frames());
  static const _maxFrame = 256 * 1024;

  void send(Map<int, Object> fields) {
    final message = WireMessage.encode(fields);
    socket.add([...WireMessage.varint(message.length), ...message]);
  }

  Future<Map<int, Object>?> next() async =>
      await _messages.moveNext() ? _messages.current : null;

  Stream<Map<int, Object>> _frames() async* {
    final frame = BytesBuilder(copy: false);
    var remaining = 0;
    var prefix = 0;
    var shift = 0;
    await for (final byte in socket.expand((chunk) => chunk)) {
      final result = _consume(byte, frame, remaining, prefix, shift);
      (remaining, prefix, shift) = (result.$1, result.$2, result.$3);
      final message = result.$4;
      if (message != null) {
        yield message;
      }
    }
  }

  (int, int, int, Map<int, Object>?) _consume(
    int byte,
    BytesBuilder frame,
    int remaining,
    int prefix,
    int shift,
  ) {
    if (remaining > 0) {
      frame.addByte(byte);
      return (
        remaining - 1,
        0,
        0,
        remaining == 1 ? WireMessage.decode(frame.takeBytes()) : null,
      );
    }
    final length = prefix | ((byte & 127) << shift);
    if (length > _maxFrame || shift >= 21) {
      throw const FormatException('Android TV frame is too large.');
    }
    if (byte >= 128) {
      return (0, length, shift + 7, null);
    }
    if (length == 0) {
      throw const FormatException('Android TV sent an empty frame.');
    }
    return (length, 0, 0, null);
  }

  void close() {
    socket.destroy();
    unawaited(_messages.cancel());
  }
}
