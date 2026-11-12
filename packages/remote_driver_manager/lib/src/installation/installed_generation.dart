import 'integration_package.dart';
import 'verified_object.dart';

/// A verified package loaded from the content store, ready for a session.
final class InstalledGeneration {
  const InstalledGeneration(
    this.package,
    this.record, {
    this.recovered = false,
  });

  final IntegrationPackage package;
  final VerifiedObject record;

  /// True when the active object was unusable and the previous one loaded.
  final bool recovered;

  String get sha256 => record.sha256;
}
