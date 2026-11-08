import 'package:remote_core/remote_core.dart';

final class CountingCredentialStore implements CredentialStore {
  final keys = <String, String>{};
  int reads = 0, writes = 0, deletes = 0;
  bool failRead = false;
  @override
  Future<String?> read(String deviceId) async {
    reads++;
    if (failRead) {
      throw const RemoteException('credentialStorage', 'Access denied.');
    }
    return keys[deviceId];
  }

  @override
  Future<void> write(String deviceId, String credential) async {
    writes++;
    keys[deviceId] = credential;
  }

  @override
  Future<void> delete(String deviceId) async {
    deletes++;
    keys.remove(deviceId);
  }
}
