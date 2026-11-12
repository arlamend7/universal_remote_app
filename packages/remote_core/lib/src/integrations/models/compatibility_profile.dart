import '../../device.dart';
import '../enums/profile_stage.dart';
import '../functions/integration_json.dart';
import '../functions/parse_remote_capability.dart';
import 'integration_compatibility.dart';

/// A software family inside one integration. Profiles adjust behaviour; they
/// never select a different protocol engine.
final class CompatibilityProfile {
  CompatibilityProfile({
    required this.id,
    required this.stage,
    required this.compatibility,
    Iterable<RemoteCapability> disabledCapabilities = const [],
    Map<String, Object?> mappingOverrides = const {},
  }) : disabledCapabilities = Set.unmodifiable(disabledCapabilities),
       mappingOverrides = Map.unmodifiable(mappingOverrides) {
    if (!IntegrationJson.isIdentifier(id) ||
        (stage == ProfileStage.bootstrap && !compatibility.isUnrestricted)) {
      throw const FormatException('Invalid compatibility profile.');
    }
  }

  factory CompatibilityProfile.fromJson(Object? value) {
    final json = IntegrationJson.object(value, 'profile');
    IntegrationJson.keys(json, _fields, required: {'id', 'stage'});
    return CompatibilityProfile(
      id: IntegrationJson.identifier(json, 'id'),
      stage: ProfileStage.parse(json['stage']),
      compatibility: IntegrationCompatibility.fromJson(
        IntegrationJson.object(
          json['compatibility'] ?? const <String, Object?>{},
          'profile',
        ),
      ),
      disabledCapabilities: IntegrationJson.list(
        json,
        'disabledCapabilities',
      ).map(parseRemoteCapability),
      mappingOverrides: IntegrationJson.object(
        json['mappingOverrides'] ?? const <String, Object?>{},
        'mappingOverrides',
      ),
    );
  }

  static const _fields = {
    'id',
    'stage',
    'compatibility',
    'disabledCapabilities',
    'mappingOverrides',
  };

  final String id;
  final ProfileStage stage;
  final IntegrationCompatibility compatibility;
  final Set<RemoteCapability> disabledCapabilities;

  /// Operation mappings that replace the integration defaults; the runtime
  /// validates them with the same rules as `mappings.json`.
  final Map<String, Object?> mappingOverrides;

  Map<String, Object?> toJson() => {
    'id': id,
    'stage': stage.id,
    'compatibility': compatibility.toJson(),
    if (disabledCapabilities.isNotEmpty)
      'disabledCapabilities': [
        for (final capability in disabledCapabilities) capability.name,
      ],
    if (mappingOverrides.isNotEmpty) 'mappingOverrides': mappingOverrides,
  };
}
