import 'dart:async';
import 'dart:convert';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import '../../pairing/constants/default_lg_manifest.dart';
import '../models/ssap_message.dart';
import '../requests/ssap_pending_request.dart';
import '../subscriptions/ssap_subscription.dart';
import '../functions/ssap_command_error.dart';

/// Coordinates SSAP envelopes; request and subscription objects own their work.
final class SsapClient {
  SsapClient(
    this.transport, {
    this.requestTimeout = const Duration(seconds: 8),
  }) {
    _listener = transport.messages.listen(
      _receive,
      onError: _socketFailed,
      onDone: _socketClosed,
    );
  }
  final TextTransport transport;
  final Duration requestTimeout;
  late final StreamSubscription<String> _listener;
  final _pending = <String, SsapPendingRequest>{};
  final _subscriptions = <String, SsapSubscription>{};
  final _closedEvents = StreamController<void>.broadcast();
  Stream<void> get disconnected => _closedEvents.stream;
  int _sequence = 0;
  bool _closed = false;
  bool get isClosed => _closed;
  String _nextId() => 'ur_${++_sequence}';
  Future<String> register({
    String? clientKey,
    bool forcePairing = false,
    Duration timeout = const Duration(seconds: 45),
    Map<String, Object?> manifest = defaultLgManifest,
  }) async {
    final payload = await _send(
      'register',
      {
        'forcePairing': forcePairing,
        'pairingType': 'PROMPT',
        'manifest': manifest,
        if (clientKey != null) 'client-key': clientKey,
      },
      timeout: timeout,
      registration: true,
    );
    final key = payload['client-key'];
    if (key is! String || key.isEmpty) {
      throw const RemoteException(
        'protocol',
        'The TV did not return an authorized client key.',
      );
    }
    return key;
  }

  Future<Map<String, Object?>> request(
    String path, {
    Map<String, Object?> payload = const {},
    Duration? timeout,
  }) => _send('request', payload, path: path, timeout: timeout);
  Future<Map<String, Object?>> _send(
    String type,
    Map<String, Object?> payload, {
    String? path,
    Duration? timeout,
    bool registration = false,
  }) {
    if (_closed) {
      return Future.error(
        const RemoteException('disconnected', 'Connect to the TV first.'),
      );
    }
    final id = _nextId();
    final frame = jsonEncode({
      'id': id,
      'type': type,
      if (path != null) 'uri': _uri(path),
      'payload': payload,
    });
    final pending = SsapPendingRequest(
      registration: registration,
      timeout: timeout ?? requestTimeout,
      onExpired: () => _pending.remove(id),
    );
    _pending[id] = pending;
    unawaited(_write(id, frame));
    return pending.future;
  }

  Future<void> _write(String id, String frame) async {
    try {
      await transport.send(frame);
    } catch (_) {
      _reject(
        id,
        const RemoteException('network', 'Could not send the TV request.'),
      );
    }
  }

  String _uri(String path) {
    final value = path.startsWith('ssap://') ? path : 'ssap://$path';
    final uri = Uri.parse(value);
    if (uri.host.isEmpty || uri.scheme != 'ssap') {
      throw ArgumentError('Invalid SSAP URI.');
    }
    return value;
  }

  Stream<Map<String, Object?>> subscribe(String path) {
    if (_closed) {
      return Stream.error(
        const RemoteException('disconnected', 'Connect to the TV first.'),
      );
    }
    final id = _nextId();
    final subscription = SsapSubscription(
      id: id,
      uri: _uri(path),
      transport: transport,
      timeout: requestTimeout,
      onClosed: () => _subscriptions.remove(id),
    );
    _subscriptions[id] = subscription;
    return subscription.stream;
  }

  void _receive(String frame) {
    if (_closed) {
      return;
    }
    try {
      _dispatch(SsapMessage.parse(frame));
    } on FormatException {
      _terminate(
        const RemoteException(
          'protocol',
          'The TV sent an invalid protocol message.',
        ),
      );
    }
  }

  void _dispatch(SsapMessage message) {
    final id = message.id;
    if (id == null) {
      return;
    }
    if (message.isFailure) {
      _rejectMessage(id, message);
      return;
    }
    final pending = _pending[id];
    if (pending == null) {
      _notifySubscription(id, message);
      return;
    }
    // PROMPT acknowledgement must never complete authorization.
    if (!pending.accepts(message)) {
      return;
    }
    _pending.remove(id);
    pending.complete(message.payload);
  }

  void _notifySubscription(String id, SsapMessage message) {
    if (message.type != 'response') {
      return;
    }
    _subscriptions[id]?.receive(message.payload);
  }

  void _rejectMessage(String id, SsapMessage message) {
    final error = ssapCommandError(
      message.error ?? message.payload['errorCode'],
      registration: _pending[id]?.registration ?? false,
    );
    _reject(id, error);
    _subscriptions[id]?.fail(error);
  }

  void _reject(String id, RemoteException error) =>
      _pending.remove(id)?.fail(error);
  void _socketFailed(Object _, StackTrace __) =>
      _terminate(const RemoteException('network', 'The TV connection failed.'));
  void _socketClosed() =>
      _terminate(const RemoteException('disconnected', 'The TV disconnected.'));
  void _terminate(RemoteException error) {
    if (_closed) {
      return;
    }
    _closed = true;
    for (final request in _pending.values) {
      request.fail(error);
    }
    _pending.clear();
    for (final subscription in _subscriptions.values.toList()) {
      subscription.fail(error);
    }
    _subscriptions.clear();
    _closedEvents.add(null);
    unawaited(_closedEvents.close());
    unawaited(transport.close());
  }

  Future<void> close() async {
    _terminate(
      const RemoteException('disconnected', 'The TV connection was closed.'),
    );
    await _listener.cancel();
    await transport.close();
  }
}
