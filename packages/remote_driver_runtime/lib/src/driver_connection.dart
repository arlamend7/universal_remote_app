import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import 'driver_credential_scope.dart';
import 'driver_exchange.dart';
import 'driver_text_session.dart';

/// Maintains one connection and serializes requests so replies cannot cross.
final class DriverConnection {
  DriverConnection(this._open);

  final Future<TextTransport> Function(Stream<void>, Duration) _open;
  DriverTextSession? _session;
  bool _busy = false;
  final _subscriptions = <String>{};
  void Function()? _stopActive;
  Completer<void>? _operationFinished;
  void Function()? onLost;
  bool get connected => _session != null;
  int _sequence = 0;
  void Function(Map<String, Object?>)? onFeedback;

  Future<void> connect({
    Duration timeout = const Duration(seconds: 5),
    Stream<void>? cancellation,
  }) {
    if (_session != null) {
      throw StateError('Close the driver connection before reconnecting.');
    }
    return _run(
      (stop, active) async {
        final transport = await _open(stop, timeout);
        if (!active()) {
          await transport.close();
          throw _cancelled;
        }
        _session = DriverTextSession(
          transport,
          onEvent: _feedback,
          onLost: () => onLost?.call(),
        );
      },
      timeout,
      cancellation,
    );
  }

  Future<Map<String, Object?>> request(
    DriverExchange exchange, {
    Map<String, Object> arguments = const {},
    Duration timeout = const Duration(seconds: 5),
    Stream<void>? cancellation,
  }) {
    if (!_requests.contains(exchange.operation)) {
      throw ArgumentError('Use the pairing or authentication entry point.');
    }
    return _run(
      (_, _) async {
        final event = exchange.event ?? '*';
        if (exchange.operation == DriverOperation.webSocketSubscribe) {
          _subscriptions.add(event);
        }
        if (exchange.operation == DriverOperation.webSocketUnsubscribe) {
          _subscriptions.remove(event);
        }
        final reply = await _requestReply(exchange, arguments, event);
        return Map.unmodifiable(
          reply
            ..remove('token')
            ..remove('code'),
        );
      },
      timeout,
      cancellation,
    );
  }

  Future<Map<String, Object?>> _requestReply(
    DriverExchange exchange,
    Map<String, Object> arguments,
    String event,
  ) async {
    try {
      return await _exchange(exchange, arguments: arguments);
    } on RemoteException {
      if (exchange.operation == DriverOperation.webSocketSubscribe) {
        _subscriptions.remove(event);
      }
      rethrow;
    }
  }

  Future<void> authenticate(
    DriverExchange exchange,
    DriverCredentialScope credentials, {
    Duration timeout = const Duration(seconds: 5),
    Stream<void>? cancellation,
  }) {
    if (exchange.operation != DriverOperation.webSocketAuthenticate) {
      throw ArgumentError('Expected a driver authentication request.');
    }
    return _run(
      (_, active) async {
        final token = await credentials.read();
        if (token == null || token.isEmpty || token.length > 4096) {
          throw const RemoteException(
            'driverPairing',
            'Pair with the TV first.',
          );
        }
        if (!active()) {
          throw _cancelled;
        }
        await _exchange(exchange, token: token);
      },
      timeout,
      cancellation,
    );
  }

  Future<void> pair(
    DriverExchange exchange,
    DriverCredentialScope credentials, {
    required Future<String?> Function() requestCode,
    Duration timeout = const Duration(seconds: 30),
    Stream<void>? cancellation,
  }) async {
    if (exchange.operation != DriverOperation.webSocketPair) {
      throw ArgumentError('Expected a driver pairing request.');
    }
    await _run(
      (_, active) async {
        final code = await requestCode();
        if (!active() || code == null) {
          throw _cancelled;
        }
        if (!_pairingCode.hasMatch(code) || code.trim() != code) {
          throw const RemoteException('driverPairing', 'Invalid pairing code.');
        }
        final reply = await _exchange(exchange, code: code);
        final token = reply['token'];
        if (token is! String || token.isEmpty || token.length > 4096) {
          throw const RemoteException(
            'driverPairing',
            'Invalid pairing token.',
          );
        }
        if (!active()) {
          throw _cancelled;
        }
        await credentials.write(token);
      },
      timeout,
      cancellation,
    );
  }

  Future<Map<String, Object?>> _exchange(
    DriverExchange exchange, {
    String? code,
    String? token,
    Map<String, Object> arguments = const {},
  }) async {
    final session = _session;
    if (session == null) {
      throw StateError('Open the driver connection first.');
    }
    final id = ++_sequence;
    await session.send(
      exchange.encode(id, code: code, token: token, arguments: arguments),
    );
    final reply = await session.receiveJson();
    if (reply['id'] is! int || reply['id'] != id) {
      throw const RemoteException('driverResponse', 'Mismatched TV response.');
    }
    if (reply['ok'] != true) {
      throw const RemoteException(
        'driverRejected',
        'The TV refused the request.',
      );
    }
    return reply;
  }

  void _feedback(Map<String, Object?> event) {
    if (_subscriptions.contains('*') ||
        _subscriptions.contains(event['event'])) {
      onFeedback?.call(event);
    }
  }

  Future<void> close() async {
    final finished = _operationFinished;
    _stopActive?.call();
    await finished?.future;
    await _disconnect();
  }

  Future<void> _disconnect() async {
    final session = _session;
    _session = null;
    _subscriptions.clear();
    await session?.close();
  }

  Future<T> _run<T>(
    Future<T> Function(Stream<void>, bool Function()) action,
    Duration timeout,
    Stream<void>? cancellation,
  ) async {
    if (_busy) {
      throw StateError('A driver operation is already in progress.');
    }
    if (timeout <= Duration.zero || timeout > const Duration(seconds: 30)) {
      throw ArgumentError(
        'Driver operation timeout must be within 30 seconds.',
      );
    }
    _busy = true;
    final finished = _operationFinished = Completer<void>();
    final interrupted = Completer<Never>();
    final stop = StreamController<void>.broadcast();
    var active = true;

    void interrupt(RemoteException error) {
      if (active && !interrupted.isCompleted) {
        interrupted.completeError(error);
        stop.add(null);
      }
    }

    _stopActive = () => interrupt(_cancelled);
    final timer = Timer(timeout, () => interrupt(_timedOut));
    StreamSubscription<void>? listener;
    try {
      listener = cancellation?.listen(
        (_) => interrupt(_cancelled),
        onError: (Object _) => interrupt(_cancelled),
      );
      final result = Future.sync(
        () => action(stop.stream, () => active && !interrupted.isCompleted),
      );
      return await Future.any([interrupted.future, result]);
    } catch (error) {
      active = false;
      if (error is! RemoteException || error.code != 'driverRejected') {
        await _disconnect();
      }
      rethrow;
    } finally {
      active = false;
      timer.cancel();
      await listener?.cancel();
      await stop.close();
      _busy = false;
      _stopActive = null;
      _operationFinished = null;
      finished.complete();
    }
  }

  static final _pairingCode = RegExp(r'^[a-zA-Z0-9]{1,12}$');
  static const _requests = {
    DriverOperation.webSocketRequest,
    DriverOperation.webSocketSubscribe,
    DriverOperation.webSocketUnsubscribe,
  };
  static const _cancelled = RemoteException(
    'cancelled',
    'Driver operation cancelled.',
  );
  static const _timedOut = RemoteException(
    'driverTimeout',
    'Driver operation timed out.',
  );
}
