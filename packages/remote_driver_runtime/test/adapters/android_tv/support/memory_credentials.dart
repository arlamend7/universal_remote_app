import 'package:remote_core/remote_core.dart';

final class MemoryCredentials implements CredentialStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String deviceId) async => values[deviceId];

  @override
  Future<void> write(String deviceId, String credential) async =>
      values[deviceId] = credential;

  @override
  Future<void> delete(String deviceId) async => values.remove(deviceId);
}
