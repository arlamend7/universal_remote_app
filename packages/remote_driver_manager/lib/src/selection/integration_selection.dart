import 'package:remote_core/remote_core.dart';

import 'integration_candidate.dart';
import 'selection_stage.dart';

/// The integration and compatibility profile chosen for one device.
final class IntegrationSelection {
  const IntegrationSelection(
    this.candidate,
    this.profile,
    this.stage, {
    required this.reason,
  });

  final IntegrationCandidate candidate;
  final CompatibilityProfile profile;
  final SelectionStage stage;

  /// Human-readable explanation for diagnostics.
  final String reason;

  IntegrationIdentity get identity => candidate.identity;
}
