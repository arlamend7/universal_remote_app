import 'package:flutter/services.dart';

import '../../../domains/storage/contracts/application_storage.dart';

/// Ordinary UI preferences only. Pairing credentials must never use this adapter.
final class NativePreferencesStorage implements ApplicationStorage {
  NativePreferencesStorage({MethodChannel? channel})
    : _channel =
          channel ??
          const MethodChannel('br.net.devcom.universal_remote/preferences');
  final MethodChannel _channel;
  static const keys = {
    'saved-devices.v2',
    'dashboards.v2',
    'settings.theme',
    'settings.diagnostics',
    'settings.accent',
    'settings.feedback',
    'settings.autoReconnect',
    'settings.screenAwake',
    'settings.welcomeCompleted',
    'active-session.v1',
  };
  void _validate(String key) {
    if (keys.contains(key)) {
      return;
    }
    throw ArgumentError(
      'Only non-secret application preferences are allowed here.',
    );
  }

  @override
  Future<String?> read(String key) {
    _validate(key);
    return _channel.invokeMethod<String>('read', {'key': key});
  }

  @override
  Future<void> write(String key, String value) {
    _validate(key);
    return _channel.invokeMethod<void>('write', {'key': key, 'value': value});
  }

  @override
  Future<void> delete(String key) {
    _validate(key);
    return _channel.invokeMethod<void>('delete', {'key': key});
  }
}
