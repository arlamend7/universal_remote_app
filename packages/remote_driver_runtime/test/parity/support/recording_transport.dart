import 'dart:async';
import 'dart:convert';

import 'package:remote_network/remote_network.dart';

import 'parity_recorder.dart';

/// Records outgoing frames; JSON request ids are dropped as they are volatile.
final class RecordingTransport implements TextTransport {
  RecordingTransport(this.inner, this.recorder, this.channel);

  final TextTransport inner;
  final ParityRecorder recorder;
  final String channel;

  @override
  Stream<String> get messages => inner.messages;

  @override
  FutureOr<void> send(String message) {
    recorder.add({channel: _frame(message)});
    return inner.send(message);
  }

  Object? _frame(String message) {
    if (!message.startsWith('{')) {
      return message;
    }
    final decoded = jsonDecode(message) as Map<String, Object?>;
    return {...decoded}..remove('id');
  }

  @override
  Future<void> close() => inner.close();
}
