import 'package:remote_core/remote_core.dart';

import 'driver_match.dart';

abstract final class DriverVersionResolver {
  static bool supports(
    DriverRuntimeRequirements requirements,
    DriverVersion runtime,
  ) {
    final upper = requirements.before;
    return runtime.compareTo(requirements.minimum) >= 0 &&
        (upper == null || runtime.compareTo(upper) < 0);
  }

  /// Package versions are comparable only within the same driver family.
  static int preferredRelease(DriverMatch a, DriverMatch b) {
    final version = a.candidate.identity.version.compareTo(
      b.candidate.identity.version,
    );
    return version != 0
        ? version
        : a.profile.version.compareTo(b.profile.version);
  }
}
