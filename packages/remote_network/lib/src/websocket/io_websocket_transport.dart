import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/src/transport/contracts/text_transport.dart';
import 'package:remote_network/src/transport/models/enums/transport_state.dart';

final class IoWebSocketTransport implements TextTransport {
  IoWebSocketTransport._(this._socket) {
    _subscription = _socket.listen(_receive, onError: _failed, onDone: _finish);
  }
  void _receive(Object? message) {
    if (message is! String) {
      _messages.addError(const FormatException('Expected a text frame.'));
      return;
    }
    _messages.add(message);
  }

  void _failed(Object error, StackTrace stack) {
    _messages.addError(error, stack);
    _finish();
  }

  final WebSocket _socket;
  final _messages = StreamController<String>();
  final _states = StreamController<TransportState>.broadcast();
  late final StreamSubscription<Object?> _subscription;
  bool _closed = false;
  TransportState get state =>
      _closed ? TransportState.closed : TransportState.open;
  Stream<TransportState> get states => _states.stream;

  /// Optional exact DER certificate pin, provisioned by the user out of band.
  /// A pin only accepts this certificate on this endpoint; no global overrides.
  static Future<IoWebSocketTransport> connect(
    Uri endpoint, {
    Duration timeout = const Duration(seconds: 5),
    String? trustedCertificateDer,
    Stream<void>? cancellation,
  }) async {
    if (!{'ws', 'wss'}.contains(endpoint.scheme) ||
        endpoint.host.isEmpty ||
        endpoint.userInfo.isNotEmpty ||
        endpoint.hasFragment) {
      throw ArgumentError('Expected a WebSocket URL without credentials.');
    }
    if (timeout <= Duration.zero) {
      throw ArgumentError('Timeout must be positive.');
    }
    final trusted = trustedCertificateDer == null
        ? null
        : base64Encode(base64Decode(trustedCertificateDer));
    // An empty trust store ensures a configured pin is checked for every
    // certificate, including certificates normally trusted by the system.
    final client = HttpClient(
      context: trusted == null
          ? null
          : SecurityContext(withTrustedRoots: false),
    )..connectionTimeout = timeout;
    if (trusted != null) {
      client.badCertificateCallback = (certificate, host, port) =>
          host == endpoint.host &&
          port == endpoint.port &&
          base64Encode(certificate.der) == trusted;
    }
    final stopped = Completer<Never>();
    var accepting = true;
    StreamSubscription<void>? cancel;
    try {
      cancel = cancellation?.listen(
        (_) => _cancelConnection(stopped),
        onError: (Object _, StackTrace __) => _cancelConnection(stopped),
      );
      // Socket ownership transfers only if the attempt is still active.
      final connecting =
          WebSocket.connect(
            endpoint.toString(),
            customClient: client,
            maxPayloadLength: 2 * 1024 * 1024,
          ).then((socket) async {
            if (!accepting || stopped.isCompleted) {
              await socket.close(WebSocketStatus.goingAway);
              throw const RemoteException(
                'cancelled',
                'WebSocket connection ended.',
              );
            }
            return socket;
          });
      // The transport takes ownership of the accepted socket.
      // ignore: close_sinks
      final socket = await Future.any([
        connecting,
        if (cancel != null) stopped.future,
      ]).timeout(timeout);
      socket.pingInterval = const Duration(seconds: 20);
      return IoWebSocketTransport._(socket);
    } finally {
      accepting = false;
      client.close(force: true);
      await cancel?.cancel();
    }
  }

  static void _cancelConnection(Completer<Never> stopped) {
    if (!stopped.isCompleted) {
      stopped.completeError(
        const RemoteException('cancelled', 'WebSocket connection cancelled.'),
      );
    }
  }

  @override
  Stream<String> get messages => _messages.stream;
  @override
  void send(String message) {
    if (_closed || _socket.readyState != WebSocket.open) {
      throw StateError('WebSocket is not open.');
    }
    _socket.add(message);
  }

  void _finish() {
    if (_closed) {
      return;
    }
    _closed = true;
    _socket.pingInterval = null;
    _states.add(TransportState.closed);
    unawaited(_states.close());
    unawaited(_messages.close());
  }

  @override
  Future<void> close() async {
    _finish();
    await _socket
        .close(WebSocketStatus.normalClosure)
        .timeout(const Duration(seconds: 2), onTimeout: () {});
    await _subscription.cancel();
  }
}
