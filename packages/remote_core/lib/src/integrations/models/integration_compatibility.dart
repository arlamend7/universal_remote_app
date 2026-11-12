import '../enums/version_match.dart';
import '../enums/version_scheme.dart';
import '../functions/integration_json.dart';
import 'version_range.dart';

/// The physical devices an integration (or one of its profiles) targets.
final class IntegrationCompatibility {
  IntegrationCompatibility({
    this.osVersion,
    this.firmwareVersion,
    Iterable<String> models = const [],
    this.versionScheme = VersionScheme.dottedNumeric,
  }) : models = Set.unmodifiable(models);

  factory IntegrationCompatibility.fromJson(Map<String, Object?> json) {
    IntegrationJson.keys(json, _fields);
    final scheme = json.containsKey('versionScheme')
        ? VersionScheme.parse(json['versionScheme'])
        : VersionScheme.dottedNumeric;
    return IntegrationCompatibility(
      osVersion: _range(json, 'osVersion', scheme),
      firmwareVersion: _range(json, 'firmwareVersion', scheme),
      models: IntegrationJson.labels(json, 'models'),
      versionScheme: scheme,
    );
  }

  static const _fields = {
    'osVersion',
    'firmwareVersion',
    'models',
    'versionScheme',
  };

  final VersionRange? osVersion, firmwareVersion;
  final Set<String> models;
  final VersionScheme versionScheme;

  bool get isUnrestricted =>
      osVersion == null && firmwareVersion == null && models.isEmpty;

  /// Unknown device evidence never counts as a match for a declared range.
  VersionMatch match({String? os, String? firmware, String? model}) {
    final results = [
      if (osVersion != null) osVersion!.match(os, versionScheme),
      if (firmwareVersion != null)
        firmwareVersion!.match(firmware, versionScheme),
      if (models.isNotEmpty) _model(model),
    ];
    if (results.contains(VersionMatch.mismatches)) {
      return VersionMatch.mismatches;
    }
    if (results.contains(VersionMatch.unknown)) {
      return VersionMatch.unknown;
    }
    return VersionMatch.matches;
  }

  VersionMatch _model(String? model) {
    if (model == null || model.isEmpty) {
      return VersionMatch.unknown;
    }
    return models.contains(model)
        ? VersionMatch.matches
        : VersionMatch.mismatches;
  }

  Map<String, Object?> toJson() => {
    if (osVersion != null) 'osVersion': osVersion!.expression,
    if (firmwareVersion != null) 'firmwareVersion': firmwareVersion!.expression,
    if (models.isNotEmpty) 'models': models.toList(),
    'versionScheme': versionScheme.id,
  };

  static VersionRange? _range(
    Map<String, Object?> json,
    String key,
    VersionScheme scheme,
  ) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('Invalid device version range: $key.');
    }
    return VersionRange.parse(value, scheme);
  }
}
