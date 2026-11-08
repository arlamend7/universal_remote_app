import 'dart:async';

import 'package:remote_core/remote_core.dart';

import '../models/ssap_message.dart';

/// Owns the completion and deadline of exactly one request.
final class SsapPendingRequest {
  SsapPendingRequest({
    required this.registration,
    required Duration timeout,
    required this.onExpired,
  }) {
    _timer = Timer(timeout, _expire);
  }
  final bool registration;
  final void Function() onExpired;
  final _completer = Completer<Map<String, Object?>>();
  late final Timer _timer;
  Future<Map<String, Object?>> get future => _completer.future;
  bool accepts(SsapMessage message) =>
      message.type == (registration ? 'registered' : 'response');
  void complete(Map<String, Object?> payload) {
    if (_completer.isCompleted) {
      return;
    }
    _timer.cancel();
    _completer.complete(payload);
  }

  void fail(RemoteException error) {
    if (_completer.isCompleted) {
      return;
    }
    _timer.cancel();
    _completer.completeError(error);
  }

  void _expire() {
    onExpired();
    fail(
      RemoteException(
        registration ? 'pairingTimeout' : 'timeout',
        registration
            ? 'TV approval timed out. Please retry pairing.'
            : 'The TV did not respond in time.',
      ),
    );
  }
}
