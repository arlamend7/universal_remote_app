import 'package:remote_core/remote_core.dart';

final class SamsungTestCredentials implements CredentialStore {
  String? saved;

  @override
  Future<String?> read(String deviceId) async => saved;

  @override
  Future<void> write(String deviceId, String credential) async {
    saved = credential;
  }

  @override
  Future<void> delete(String deviceId) async {
    saved = null;
  }
}
