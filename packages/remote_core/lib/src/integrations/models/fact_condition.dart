import '../functions/integration_json.dart';

/// A session fact a capability depends on, such as a negotiated feature.
///
/// When the fact is absent the [fallback] condition decides, then [missing];
/// without either the capability stays conditional rather than assumed.
final class FactCondition {
  FactCondition({
    required this.fact,
    required this.equals,
    this.fallback,
    this.missing,
  }) {
    if (!IntegrationJson.isIdentifier(fact) || equals.length > 128) {
      throw const FormatException('Invalid capability fact condition.');
    }
  }

  factory FactCondition.fromJson(Object? value, {int depth = 0}) {
    final json = IntegrationJson.object(value, 'condition');
    IntegrationJson.keys(
      json,
      const {'fact', 'equals', 'otherwise', 'missing'},
      required: const {'fact', 'equals'},
    );
    final otherwise = json['otherwise'];
    final missing = json['missing'];
    if (depth > 2 ||
        json['equals'] is! String ||
        (missing != null && missing is! bool)) {
      throw const FormatException('Invalid capability fact condition.');
    }
    return FactCondition(
      fact: IntegrationJson.identifier(json, 'fact'),
      equals: json['equals']! as String,
      fallback: otherwise == null
          ? null
          : FactCondition.fromJson(otherwise, depth: depth + 1),
      missing: missing as bool?,
    );
  }

  final String fact;
  final String equals;
  final FactCondition? fallback;

  /// The decision when neither the fact nor the fallback is reported.
  final bool? missing;

  /// True or false when decided, or null when the session reported nothing.
  bool? evaluate(Map<String, String> facts) {
    final reported = facts[fact];
    if (reported != null) {
      return reported == equals;
    }
    return fallback?.evaluate(facts) ?? missing;
  }

  Map<String, Object?> toJson() => {
    'fact': fact,
    'equals': equals,
    if (fallback != null) 'otherwise': fallback!.toJson(),
    'missing': ?missing,
  };
}
