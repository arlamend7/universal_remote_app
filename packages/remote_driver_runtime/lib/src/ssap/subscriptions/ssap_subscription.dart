import 'dart:async';
import 'dart:convert';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

/// Owns a subscription stream, its initial response deadline and unsubscribe.
final class SsapSubscription {
  SsapSubscription({
    required this.id,
    required this.uri,
    required this.transport,
    required this.timeout,
    required this.onClosed,
  }) {
    _controller = StreamController<Map<String, Object?>>(
      onListen: _start,
      onCancel: _cancel,
    );
  }
  final String id;
  final String uri;
  final TextTransport transport;
  final Duration timeout;
  final void Function() onClosed;
  late final StreamController<Map<String, Object?>> _controller;
  Timer? _timer;
  bool _closed = false;
  Stream<Map<String, Object?>> get stream => _controller.stream;
  void receive(Map<String, Object?> payload) {
    if (_closed) {
      return;
    }
    _timer?.cancel();
    _controller.add(payload);
  }

  void fail(RemoteException error) {
    if (_closed) {
      return;
    }
    _controller.addError(error);
    unawaited(_cancel());
    unawaited(_controller.close());
  }

  Future<void> _start() async {
    if (_closed) {
      return;
    }
    _timer = Timer(timeout, _expire);
    try {
      await transport.send(
        jsonEncode({
          'id': id,
          'type': 'subscribe',
          'uri': uri,
          'payload': <String, Object?>{},
        }),
      );
    } catch (_) {
      fail(
        const RemoteException('network', 'Could not subscribe to TV updates.'),
      );
    }
  }

  void _expire() =>
      fail(const RemoteException('timeout', 'The TV subscription timed out.'));
  Future<void> _cancel() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _timer?.cancel();
    onClosed();
    try {
      await transport.send(jsonEncode({'id': id, 'type': 'unsubscribe'}));
    } catch (_) {
      /* The session may already be closed. */
    }
  }
}
