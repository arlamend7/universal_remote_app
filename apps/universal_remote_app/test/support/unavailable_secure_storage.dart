import 'package:flutter/services.dart';
import 'package:universal_remote_app/domains/storage/contracts/application_storage.dart';

class UnavailableSecureStorage implements ApplicationStorage {
  @override
  Future<String?> read(String key) async => throw PlatformException(
    code: 'storage',
    message: 'sensitive native detail',
  );
  @override
  Future<void> write(String key, String value) async =>
      throw PlatformException(code: 'storage', message: value);
  @override
  Future<void> delete(String key) async => throw PlatformException(
    code: 'storage',
    message: 'sensitive native detail',
  );
}
