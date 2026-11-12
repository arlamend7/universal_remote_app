import '../../device.dart';
import '../functions/integration_json.dart';
import '../functions/parse_remote_capability.dart';
import 'capability_verification.dart';
import 'fact_condition.dart';
import 'integration_compatibility.dart';

/// How an integration implements one capability (`capabilities.json`).
///
/// The capability is executable when every operation of at least one
/// [alternatives] set is mapped; the first complete set is used.
final class CapabilityDeclaration {
  CapabilityDeclaration({
    required this.capability,
    required Iterable<List<String>> alternatives,
    this.availability = CapabilityAvailability.known,
    this.verification,
    Iterable<FactCondition> conditions = const [],
    this.restrictions,
    Iterable<String> permissions = const [],
    Iterable<String> disableOn = const [],
    this.reason,
  }) : alternatives = List.unmodifiable([
         for (final set in alternatives) List<String>.unmodifiable(set),
       ]),
       conditions = List.unmodifiable(conditions),
       permissions = Set.unmodifiable(permissions),
       disableOn = Set.unmodifiable(disableOn) {
    if (this.alternatives.isEmpty ||
        this.alternatives.any(
          (set) => set.isEmpty || !set.every(IntegrationJson.isIdentifier),
        ) ||
        !{
          CapabilityAvailability.known,
          CapabilityAvailability.verified,
          CapabilityAvailability.conditional,
        }.contains(availability)) {
      throw const FormatException('Invalid capability declaration.');
    }
  }

  factory CapabilityDeclaration.fromJson(String name, Object? value) {
    final json = IntegrationJson.object(value, name);
    IntegrationJson.keys(json, _fields, required: const {'alternatives'});
    return CapabilityDeclaration(
      capability: parseRemoteCapability(name),
      alternatives: IntegrationJson.list(
        json,
        'alternatives',
        maximum: 16,
      ).map(_set),
      availability: _availability(json['availability']),
      verification: json['verify'] == null
          ? null
          : CapabilityVerification.fromJson(json['verify']),
      conditions: IntegrationJson.list(
        json,
        'when',
        maximum: 8,
      ).map(FactCondition.fromJson),
      restrictions: json['restrictions'] == null
          ? null
          : IntegrationCompatibility.fromJson(
              IntegrationJson.object(json['restrictions'], 'restrictions'),
            ),
      permissions: IntegrationJson.labels(json, 'permissions'),
      disableOn: IntegrationJson.labels(json, 'disableOn'),
      reason: IntegrationJson.optionalLabel(json, 'reason'),
    );
  }

  static const _fields = {
    'alternatives',
    'availability',
    'verify',
    'when',
    'restrictions',
    'permissions',
    'disableOn',
    'reason',
  };

  final RemoteCapability capability;
  final List<List<String>> alternatives;

  /// Evidence when no verification probe is declared.
  final CapabilityAvailability availability;
  final CapabilityVerification? verification;

  /// All conditions must hold; an undecided condition leaves it conditional.
  final List<FactCondition> conditions;

  /// Device software or models this capability is limited to.
  final IntegrationCompatibility? restrictions;

  /// Protocol permissions the capability needs, shown in diagnostics.
  final Set<String> permissions;

  /// Error codes that make the session withdraw the capability.
  final Set<String> disableOn;
  final String? reason;

  /// Every operation named by any alternative or the verification probe.
  Set<String> get operations => {
    for (final set in alternatives) ...set,
    if (verification != null) verification!.operation,
  };

  /// The first operation set fully provided by [available].
  List<String>? select(bool Function(String operation) available) {
    for (final set in alternatives) {
      if (set.every(available)) {
        return set;
      }
    }
    return null;
  }

  static List<String> _set(Object? value) {
    if (value is! List<Object?> ||
        value.length > 32 ||
        !value.every(
          (operation) =>
              operation is String && IntegrationJson.isIdentifier(operation),
        )) {
      throw const FormatException('Invalid capability operation set.');
    }
    return value.cast<String>();
  }

  static CapabilityAvailability _availability(Object? value) => switch (value) {
    null || 'known' => CapabilityAvailability.known,
    'verified' => CapabilityAvailability.verified,
    'conditional' => CapabilityAvailability.conditional,
    _ => throw const FormatException('Invalid capability availability.'),
  };
}
