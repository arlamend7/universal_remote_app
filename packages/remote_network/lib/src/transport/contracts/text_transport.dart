import 'dart:async';

/// Each instance owns one connection. Protocol clients own reconnection.
abstract interface class TextTransport {
  Stream<String> get messages;
  FutureOr<void> send(String message);
  Future<void> close();
}
