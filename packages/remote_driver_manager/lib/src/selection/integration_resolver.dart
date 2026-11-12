import 'package:remote_core/remote_core.dart';

import 'integration_candidate.dart';
import 'integration_selection.dart';
import 'selection_stage.dart';

/// Two-stage compatibility resolution.
///
/// Stage 1 picks a safe bootstrap integration from the provider family and
/// any model evidence; firmware is never assumed before pairing. Stage 2
/// refines the choice from software the authenticated session reported;
/// unknown software never selects a restricted integration or profile.
abstract final class IntegrationResolver {
  static IntegrationSelection? bootstrap(
    String providerId,
    Iterable<IntegrationCandidate> candidates, {
    String? model,
    String? assigned,
    bool allowDevelopment = false,
  }) {
    final family = _family(
      providerId,
      candidates,
      allowDevelopment,
    ).where((candidate) => _modelAllowed(candidate, model)).toList();
    if (family.isEmpty) {
      return null;
    }
    final previous = family.where((candidate) => candidate.id == assigned);
    final chosen = previous.isNotEmpty ? previous.single : _best(family);
    return IntegrationSelection(
      chosen,
      chosen.bootstrapProfile,
      SelectionStage.bootstrap,
      reason: previous.isNotEmpty
          ? 'Previously assigned integration.'
          : 'Highest-priority integration for this provider.',
    );
  }

  /// Returns the refined selection; a different integration means a handoff.
  static IntegrationSelection identified(
    IntegrationSelection current,
    Iterable<IntegrationCandidate> candidates,
    DeviceSoftwareInformation? software, {
    String? model,
    bool allowDevelopment = false,
  }) {
    final family = _family(
      current.identity.providerId,
      candidates,
      allowDevelopment,
    ).toList();
    final matching = family
        .where(
          (candidate) =>
              candidate.compatibility.matchSoftware(software, model: model) ==
              VersionMatch.matches,
        )
        .toList();
    final stays = matching.any(
      (candidate) => candidate.id == current.candidate.id,
    );
    if (stays || matching.isEmpty) {
      return IntegrationSelection(
        current.candidate,
        profile(current.candidate, software, model: model),
        SelectionStage.identified,
        reason: stays ? 'The TV software matches this integration.' : 'No integration declares this TV software; keeping the bootstrap choice.',
      );
    }
    final replacement = _best(matching);
    return IntegrationSelection(
      replacement,
      profile(replacement, software, model: model),
      SelectionStage.identified,
      reason: 'The TV software matches ${replacement.id}.',
    );
  }

  /// The first identified profile whose ranges match, else the bootstrap.
  static CompatibilityProfile profile(
    IntegrationCandidate candidate,
    DeviceSoftwareInformation? software, {
    String? model,
  }) =>
      candidate.profiles
          .where((profile) => profile.stage == ProfileStage.identified)
          .where(
            (profile) =>
                profile.compatibility.matchSoftware(software, model: model) ==
                VersionMatch.matches,
          )
          .firstOrNull ??
      candidate.bootstrapProfile;

  static Iterable<IntegrationCandidate> _family(
    String providerId,
    Iterable<IntegrationCandidate> candidates,
    bool allowDevelopment,
  ) => candidates.where(
    (candidate) =>
        candidate.identity.providerId == providerId &&
        (allowDevelopment || !candidate.development),
  );

  static bool _modelAllowed(IntegrationCandidate candidate, String? model) {
    final models = candidate.compatibility.models;
    return models.isEmpty || model == null || models.contains(model);
  }

  static IntegrationCandidate _best(List<IntegrationCandidate> candidates) =>
      (candidates.toList()..sort((a, b) {
            final priority = b.priority.compareTo(a.priority);
            return priority != 0 ? priority : a.id.compareTo(b.id);
          }))
          .first;
}
