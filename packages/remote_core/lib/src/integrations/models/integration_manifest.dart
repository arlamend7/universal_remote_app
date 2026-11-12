import '../../device.dart';
import '../enums/credential_scope.dart';
import '../enums/profile_stage.dart';
import '../functions/integration_json.dart';
import '../functions/parse_remote_capability.dart';
import 'compatibility_profile.dart';
import 'integration_compatibility.dart';
import 'integration_identity.dart';
import 'runtime_requirement.dart';

/// Package metadata for one integration (`manifest.json`, schema 2).
///
/// An integration has a stable identity and no release number: its content
/// hash identifies a generation and [lastUpdatedAt] dates the last publication.
final class IntegrationManifest {
  IntegrationManifest({
    required this.identity,
    required this.name,
    required this.manufacturer,
    required this.platform,
    required this.engine,
    required this.runtime,
    required this.compatibility,
    required Iterable<CompatibilityProfile> profiles,
    required Iterable<RemoteCapability> capabilities,
    this.credentialScope = CredentialScope.device,
    this.lastUpdatedAt,
    Iterable<String> replaces = const [],
  }) : profiles = List.unmodifiable(profiles),
       capabilities = Set.unmodifiable(capabilities),
       replaces = Set.unmodifiable(replaces) {
    final ids = this.profiles.map((profile) => profile.id).toSet();
    if (![name, manufacturer, platform].every(IntegrationJson.isLabel) ||
        !IntegrationJson.isIdentifier(engine) ||
        ids.length != this.profiles.length ||
        !this.profiles.any(
          (profile) => profile.stage == ProfileStage.bootstrap,
        ) ||
        this.profiles.any(
          (profile) =>
              !this.capabilities.containsAll(profile.disabledCapabilities),
        ) ||
        !this.replaces.every(IntegrationJson.isIdentifier)) {
      throw const FormatException('Invalid integration manifest.');
    }
  }

  factory IntegrationManifest.fromJson(Map<String, Object?> json) {
    IntegrationJson.keys(json, _fields, required: _required);
    if (json['schemaVersion'] != schemaVersion) {
      throw const FormatException('Unsupported integration manifest schema.');
    }
    final updated = json['lastUpdatedAt'];
    return IntegrationManifest(
      identity: IntegrationIdentity(
        integrationId: IntegrationJson.identifier(json, 'integrationId'),
        providerId: IntegrationJson.identifier(json, 'providerId'),
      ),
      name: IntegrationJson.label(json, 'name'),
      manufacturer: IntegrationJson.label(json, 'manufacturer'),
      platform: IntegrationJson.label(json, 'platform'),
      engine: IntegrationJson.identifier(json, 'engine'),
      runtime: RuntimeRequirement.fromJson(json['requiredRuntime']),
      credentialScope: json.containsKey('credentialScope')
          ? CredentialScope.parse(json['credentialScope'])
          : CredentialScope.device,
      compatibility: IntegrationCompatibility.fromJson(
        IntegrationJson.object(json['compatibility'], 'compatibility'),
      ),
      profiles: IntegrationJson.list(
        json,
        'profiles',
        maximum: 64,
      ).map(CompatibilityProfile.fromJson),
      capabilities: IntegrationJson.list(
        json,
        'capabilities',
      ).map(parseRemoteCapability),
      lastUpdatedAt: updated == null
          ? null
          : IntegrationJson.timestamp(updated, 'lastUpdatedAt'),
      replaces: IntegrationJson.list(json, 'replaces').map(_identifier),
    );
  }

  static const schemaVersion = 2;
  static const _required = {
    'schemaVersion',
    'integrationId',
    'providerId',
    'name',
    'manufacturer',
    'platform',
    'engine',
    'requiredRuntime',
    'compatibility',
    'profiles',
    'capabilities',
  };
  static const _fields = {
    ..._required,
    'credentialScope',
    'lastUpdatedAt',
    'replaces',
  };

  final IntegrationIdentity identity;
  final String name, manufacturer, platform;

  /// The compiled protocol engine that executes this integration.
  final String engine;
  final RuntimeRequirement runtime;
  final CredentialScope credentialScope;
  final IntegrationCompatibility compatibility;
  final List<CompatibilityProfile> profiles;
  final Set<RemoteCapability> capabilities;

  /// Stamped by the publisher; absent only in unpublished local sources.
  final DateTime? lastUpdatedAt;

  /// Retired driver family IDs whose device assignments migrate here.
  final Set<String> replaces;

  CompatibilityProfile get bootstrapProfile =>
      profiles.firstWhere((profile) => profile.stage == ProfileStage.bootstrap);

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'integrationId': identity.integrationId,
    'providerId': identity.providerId,
    'name': name,
    'manufacturer': manufacturer,
    'platform': platform,
    'engine': engine,
    'requiredRuntime': runtime.toJson(),
    'credentialScope': credentialScope.id,
    'compatibility': compatibility.toJson(),
    'profiles': [for (final profile in profiles) profile.toJson()],
    'capabilities': [for (final capability in capabilities) capability.name],
    if (lastUpdatedAt != null)
      'lastUpdatedAt': IntegrationJson.formatTimestamp(lastUpdatedAt!),
    if (replaces.isNotEmpty) 'replaces': replaces.toList(),
  };

  static String _identifier(Object? value) {
    if (value is! String || !IntegrationJson.isIdentifier(value)) {
      throw const FormatException('Invalid replaced driver family ID.');
    }
    return value;
  }
}
