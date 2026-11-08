/// Small storage seam permits deterministic tests without native plugins.
abstract interface class ApplicationStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}
