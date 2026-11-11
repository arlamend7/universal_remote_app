import 'package:remote_core/remote_core.dart';

final class MemoryDriverCredentials implements CredentialStore {
  final _values = <String, String>{};

  @override
  Future<String?> read(String deviceId) async => _values[deviceId];

  @override
  Future<void> write(String deviceId, String credential) async {
    _values[deviceId] = credential;
  }

  @override
  Future<void> delete(String deviceId) async {
    _values.remove(deviceId);
  }
}
