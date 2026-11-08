import 'dart:io';

import 'package:flutter/services.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/domains/storage/contracts/application_storage.dart';

final class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore(this.storage);
  final ApplicationStorage storage;
  @override
  Future<String?> read(String deviceId) =>
      _protect(() => storage.read('client-key.$deviceId'), 'read');
  @override
  Future<void> write(String deviceId, String credential) =>
      _protect(() => storage.write('client-key.$deviceId', credential), 'save');
  @override
  Future<void> delete(String deviceId) =>
      _protect(() => storage.delete('client-key.$deviceId'), 'delete');
  Future<T> _protect<T>(Future<T> Function() operation, String action) async {
    try {
      return await operation();
    } on PlatformException {
      final hint = Platform.isMacOS
          ? 'Allow Keychain access when macOS asks, then retry.'
          : 'Check this device’s secure-storage access and retry.';
      throw RemoteException(
        'credentialStorage',
        'Could not $action the TV’s protected pairing key. $hint',
      );
    }
  }
}
