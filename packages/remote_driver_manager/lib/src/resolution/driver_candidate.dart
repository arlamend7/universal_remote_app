import 'package:remote_core/remote_core.dart';

final class DriverCandidate {
  const DriverCandidate(
    this.manifest, {
    this.installed = false,
    this.preferred = false,
  });

  final DriverManifest manifest;
  final bool installed, preferred;

  DriverIdentity get identity => manifest.identity;
}
