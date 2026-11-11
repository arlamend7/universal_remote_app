import 'package:remote_core/remote_core.dart';

final class DriverCandidate {
  const DriverCandidate(this.manifest, {this.installed = false});

  final DriverManifest manifest;
  final bool installed;

  DriverIdentity get identity => manifest.identity;
}
