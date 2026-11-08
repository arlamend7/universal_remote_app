/// Implementations must store secrets in operating-system protected storage.
abstract interface class CredentialStore {
  Future<String?> read(String deviceId);
  Future<void> write(String deviceId, String credential);
  Future<void> delete(String deviceId);
}
