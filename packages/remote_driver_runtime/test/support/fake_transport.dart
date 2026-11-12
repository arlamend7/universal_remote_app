import 'dart:async';
import 'dart:convert';

import 'package:remote_network/remote_network.dart';

final class FakeTransport implements TextTransport {
  final incoming = StreamController<String>();
  final sent = <Map<String, dynamic>>[];
  final frames = <String>[];
  void Function(Map<String, dynamic>)? respond;
  bool closed = false;
  @override
  Stream<String> get messages => incoming.stream;
  @override
  void send(String message) {
    if (closed) throw StateError('closed');
    frames.add(message);
    if (message.startsWith('{')) {
      final value = jsonDecode(message) as Map<String, dynamic>;
      sent.add(value);
      respond?.call(value);
    }
  }

  void reply(
    Map<String, dynamic> request,
    Map<String, Object?> payload, {
    String type = 'response',
  }) {
    if (!closed) {
      incoming.add(
        jsonEncode({'id': request['id'], 'type': type, 'payload': payload}),
      );
    }
  }

  void reject(Map<String, dynamic> request, String error) {
    incoming.add(
      jsonEncode({'id': request['id'], 'type': 'error', 'error': error}),
    );
  }

  @override
  Future<void> close() async {
    if (closed) return;
    closed = true;
    unawaited(incoming.close());
  }
}
