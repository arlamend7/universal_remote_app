import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

final class DriverTextSession {
  DriverTextSession(this._transport) {
    _subscription = _transport.messages.listen(
      _receive,
      onError: (Object _) => _fail('Driver connection failed.'),
      onDone: () => _fail('Driver connection closed.'),
    );
  }

  final TextTransport _transport;
  final _messages = Queue<String>();
  late final StreamSubscription<String> _subscription;
  Completer<String>? _waiting;
  RemoteException? _failure;

  Future<void> send(String message) async {
    final failure = _failure;
    if (failure != null) {
      throw failure;
    }
    await _transport.send(message);
  }

  Future<Map<String, Object?>> receiveJson() async {
    if (_messages.isEmpty && _failure != null) {
      throw _failure!;
    }
    final message = _messages.isEmpty
        ? await (_waiting = Completer<String>()).future
        : _messages.removeFirst();
    final Object? value;
    try {
      value = jsonDecode(message);
    } on FormatException {
      throw const RemoteException(
        'driverResponse',
        'Expected a JSON response.',
      );
    }
    if (value is! Map<String, Object?>) {
      throw const RemoteException('driverResponse', 'Expected a JSON object.');
    }
    return value;
  }

  void _receive(String message) {
    if (_failure != null) {
      return;
    }
    if (message.length > 65536 || _messages.length >= 16) {
      _fail('Driver response exceeds the session limits.');
      return;
    }
    final waiting = _waiting;
    if (waiting == null) {
      _messages.add(message);
      return;
    }
    _waiting = null;
    waiting.complete(message);
  }

  void _fail(String message) {
    _failure ??= RemoteException('driverSession', message);
    _waiting?.completeError(_failure!);
    _waiting = null;
  }

  Future<void> close() async {
    _fail('Driver connection closed.');
    _messages.clear();
    try {
      await _subscription.cancel();
    } finally {
      await _transport.close();
    }
  }
}
