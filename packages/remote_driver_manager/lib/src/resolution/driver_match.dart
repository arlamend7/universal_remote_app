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
    this.matchedDetails = 0,
  });

  final DriverCandidate candidate;
  final DriverCompatibility profile;
  final bool modelMatched, firmwareExact, firmwareRange, osMatched;

  final int matchedDetails;

  bool get needsInstallation => !candidate.installed;
  bool get isGeneric => _rank == 0 && matchedDetails == 0;

  int compareEvidence(DriverMatch other) {
    final priority = _rank.compareTo(other._rank);
    return priority == 0
        ? matchedDetails.compareTo(other.matchedDetails)
        : priority;
  }

  int get _rank =>
      (modelMatched ? 8 : 0) +
      (firmwareExact ? 4 : 0) +
      (firmwareRange ? 2 : 0) +
      (osMatched ? 1 : 0);
}
