import 'package:remote_core/remote_core.dart';

import '../integrations/integration_definition.dart';

/// The verified integration and profile a device session will execute.
final class IntegrationPlan {
  IntegrationPlan(
    this.definition,
    this.profile, {
    this.sha256,
    this.identified = false,
    Map<String, String> metadata = const {},
  }) : metadata = Map.unmodifiable(metadata);

  final IntegrationDefinition definition;
  final CompatibilityProfile profile;

  /// SHA-256 of the installed generation, when loaded from the store.
  final String? sha256;

  /// True once the profile was chosen from authenticated software evidence.
  final bool identified;

  /// Saved-device metadata describing this selection.
  final Map<String, String> metadata;

  IntegrationIdentity get identity => definition.identity;
}
