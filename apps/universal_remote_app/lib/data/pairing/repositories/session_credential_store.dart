import 'dart:async';

import 'package:remote_core/remote_core.dart';

/// Reuses an authorized Keychain read for this process, never for the next launch.
final class SessionCredentialStore implements CredentialStore {
  SessionCredentialStore(this.delegate);
  final CredentialStore delegate;
  final _keys = <String, String?>{};
  final _pending = <String, Future<void>>{};
  bool _disposed = false;

  @override
  Future<String?> read(String deviceId) => _serial(deviceId, () async {
    if (_keys.containsKey(deviceId)) {
      return _keys[deviceId];
    }
    final value = await delegate.read(deviceId);
    _remember(deviceId, value);
    return value;
  });

  @override
  Future<void> write(String deviceId, String credential) =>
      _serial(deviceId, () async {
        if (_keys[deviceId] == credential) {
          return;
        }
        await delegate.write(deviceId, credential);
        _remember(deviceId, credential);
      });

  @override
  Future<void> delete(String deviceId) => _serial(deviceId, () async {
    _keys.remove(deviceId);
    await delegate.delete(deviceId);
  });

  void _remember(String deviceId, String? value) {
    if (!_disposed) {
      _keys[deviceId] = value;
    }
  }

  Future<T> _serial<T>(String deviceId, Future<T> Function() action) {
    final previous = _pending[deviceId] ?? Future<void>.value();
    final result = previous.then((_) {
      if (_disposed) {
        throw const RemoteException(
          'credentialStorage',
          'The app session has ended.',
        );
      }
      return action();
    });
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _pending[deviceId] = tail;
    unawaited(
      tail.then((_) {
        if (identical(_pending[deviceId], tail)) {
          _pending.remove(deviceId);
        }
      }),
    );
    return result;
  }

  void dispose() {
    _disposed = true;
    _keys.clear();
    _pending.clear();
  }
}
