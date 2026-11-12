import 'package:remote_driver_manager/remote_driver_manager.dart';

/// A published integration and its local installation, for the Explorer.
final class DriverIntegrationSummary {
  const DriverIntegrationSummary(this.entry, this.installed);

  final CatalogIntegration entry;
  final InstalledIntegration? installed;

  bool get isInstalled => installed?.current != null;

  /// A different signed generation is published than the one installed.
  bool get updateAvailable =>
      isInstalled &&
      installed!.current != entry.sha256 &&
      installed!.staged != entry.sha256 &&
      installed!.rejected != entry.sha256;

  String? get installedHash => installed?.current;
}
