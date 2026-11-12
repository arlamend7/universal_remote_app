/// What one update check changed, for diagnostics and the Driver Explorer.
final class IntegrationUpdateReport {
  const IntegrationUpdateReport({
    this.updated = const {},
    this.staged = const {},
    this.unchanged = const {},
    this.skipped = const {},
    this.failed = const {},
    this.checked = true,
  });

  /// Integration ID → newly active SHA-256.
  final Map<String, String> updated;

  /// Integration ID → SHA-256 waiting for its sessions to end.
  final Map<String, String> staged;

  /// Integrations whose installed hash already equals the catalog hash.
  final Set<String> unchanged;

  /// Integration ID → reason the catalog generation was not installed.
  final Map<String, String> skipped;

  /// Integration ID → failure message (download or verification).
  final Map<String, String> failed;

  /// False when the check was not due and nothing was contacted.
  final bool checked;
}
