import 'package:remote_core/remote_core.dart';

import 'driver_candidate.dart';

final class DriverMatch {
  const DriverMatch(
    this.candidate,
    this.profile, {
    required this.modelMatched,
    required this.firmwareExact,
    required this.firmwareRange,
    required this.osMatched,
  });

  final DriverCandidate candidate;
  final DriverCompatibility profile;
  final bool modelMatched, firmwareExact, firmwareRange, osMatched;

  bool get needsInstallation => !candidate.installed;
  bool get isGeneric =>
      !modelMatched && !firmwareExact && !firmwareRange && !osMatched;

  int compareEvidence(DriverMatch other) => _rank.compareTo(other._rank);

  int get _rank =>
      (modelMatched ? 8 : 0) +
      (firmwareExact ? 4 : 0) +
      (firmwareRange ? 2 : 0) +
      (osMatched ? 1 : 0);
}
