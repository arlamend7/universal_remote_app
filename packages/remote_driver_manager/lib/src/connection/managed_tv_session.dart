import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';

import 'decode_driver_software.dart';

/// Owns the persistent connection and its bounded queue for one TV session.
final class ManagedTvSession {
  ManagedTvSession(this._connection, this._bundle, {required this.onLost});

  final DriverConnection _connection;
  final DriverBundle _bundle;
  final void Function() onLost;
  Future<void> _tail = Future.value();
  bool _closed = false;
  int _queued = 0;

  bool get connected => !_closed && _connection.connected;

  Future<DeviceSoftwareInformation?> open({
    required DriverCredentialScope? credentials,
    required Future<String?> Function() requestCode,
    required void Function(Map<String, Object?>) feedback,
    required void Function(String) subscriptionRejected,
  }) async {
    _connection.onLost = onLost;
    _connection.onFeedback = feedback;
    await _connection.connect();
    _ensureOpen();
    await _authorize(credentials, requestCode);
    _ensureOpen();
    final software = await _readSoftware();
    for (final exchange in _bundle.exchanges.values) {
      if (exchange.operation == DriverOperation.webSocketSubscribe) {
        await _subscribe(exchange, subscriptionRejected);
      }
    }
    return software;
  }

  Future<DeviceSoftwareInformation?> _readSoftware() async {
    final exchange = _bundle.exchanges['identify-software'];
    if (exchange == null) {
      return null;
    }
    try {
      final response = await _connection.request(exchange);
      return decodeDriverSoftware(
        response['software'],
        authenticated: _bundle.exchanges.containsKey('authenticate'),
      );
    } on RemoteException catch (error) {
      if (error.code != 'driverRejected') {
        rethrow;
      }
      return null;
    }
  }

  Future<void> _authorize(
    DriverCredentialScope? credentials,
    Future<String?> Function() requestCode,
  ) async {
    final authenticate = _bundle.exchanges['authenticate'];
    if (authenticate == null) {
      return;
    }
    if (credentials == null) {
      throw const RemoteException(
        'driverPairing',
        'Protected TV credential storage is unavailable.',
      );
    }
    final pair = _bundle.exchanges['pair'];
    final stored = await credentials.read();
    _ensureOpen();
    if (stored == null && pair != null) {
      await _connection.pair(pair, credentials, requestCode: requestCode);
    }
    _ensureOpen();
    await _connection.authenticate(authenticate, credentials);
  }

  Future<void> _subscribe(
    DriverExchange exchange,
    void Function(String) rejected,
  ) async {
    _ensureOpen();
    try {
      await _connection.request(exchange);
    } on RemoteException catch (error) {
      if (error.code != 'driverRejected') {
        rethrow;
      }
      rejected(exchange.event ?? '*');
    }
  }

  Future<Map<String, Object?>> request(
    DriverExchange exchange,
    Map<String, Object> arguments,
  ) {
    if (_closed || _queued >= 16) {
      throw const RemoteException(
        'driverBusy',
        'The TV session cannot accept more commands.',
      );
    }
    _queued++;
    final result = _tail.then((_) => _request(exchange, arguments));
    _tail = result.then<void>(
      (_) => _queued--,
      onError: (Object _, StackTrace __) => _queued--,
    );
    return result;
  }

  Future<Map<String, Object?>> _request(
    DriverExchange exchange,
    Map<String, Object> arguments,
  ) async {
    if (_closed) {
      throw const RemoteException('cancelled', 'TV command cancelled.');
    }
    try {
      return await _connection.request(exchange, arguments: arguments);
    } catch (_) {
      if (!_closed && !_connection.connected) {
        onLost();
      }
      rethrow;
    }
  }

  void _ensureOpen() {
    if (_closed) {
      throw const RemoteException('cancelled', 'TV session cancelled.');
    }
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _connection.close();
    await _tail;
  }
}
