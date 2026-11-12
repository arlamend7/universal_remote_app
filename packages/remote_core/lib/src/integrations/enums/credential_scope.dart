/// Which identity owns a pairing credential in secure storage.
enum CredentialScope {
  /// One credential per physical device, shared by every integration that
  /// controls it, so moving between compatibility families never re-pairs.
  device('device'),

  /// One credential per device and integration.
  integration('integration');

  const CredentialScope(this.id);
  final String id;

  static CredentialScope parse(Object? value) {
    final scope = values.where((candidate) => candidate.id == value);
    if (scope.isEmpty) {
      throw const FormatException('Unknown credential scope.');
    }
    return scope.single;
  }
}
