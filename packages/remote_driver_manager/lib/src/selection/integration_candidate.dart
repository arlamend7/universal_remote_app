import 'package:remote_core/remote_core.dart';

import '../catalog/catalog_integration.dart';

/// Compatibility facts of one integration, from the catalog or a package.
final class IntegrationCandidate {
  IntegrationCandidate({
    required this.identity,
    required this.compatibility,
    required Iterable<CompatibilityProfile> profiles,
    this.priority = 0,
    this.development = false,
  }) : profiles = List.unmodifiable(profiles);

  factory IntegrationCandidate.catalog(CatalogIntegration entry) =>
      IntegrationCandidate(
        identity: entry.identity,
        compatibility: entry.compatibility,
        profiles: entry.profiles,
        priority: entry.priority,
        development: entry.development,
      );

  factory IntegrationCandidate.manifest(
    IntegrationManifest manifest, {
    bool development = false,
  }) => IntegrationCandidate(
    identity: manifest.identity,
    compatibility: manifest.compatibility,
    profiles: manifest.profiles,
    priority: manifest.priority,
    development: development,
  );

  final IntegrationIdentity identity;
  final IntegrationCompatibility compatibility;
  final List<CompatibilityProfile> profiles;
  final int priority;
  final bool development;

  String get id => identity.integrationId;

  CompatibilityProfile get bootstrapProfile =>
      profiles.firstWhere((profile) => profile.stage == ProfileStage.bootstrap);
}
