import 'device_information_confidence.dart';
import 'device_information_source.dart';

/// Physical TV evidence. Package, profile and runtime versions are separate.
final class DeviceSoftwareInformation {
  DeviceSoftwareInformation({
    required this.source,
    this.manufacturer,
    this.model,
    this.hardwareModel,
    this.operatingSystem,
    this.operatingSystemVersion,
    this.softwareVersion,
    this.firmwareVersion,
    this.buildNumber,
    this.protocolVersion,
    DateTime? identifiedAt,
    Map<String, String> raw = const {},
  }) : identifiedAt = identifiedAt?.toUtc(),
       raw = Map.unmodifiable(
         Map.fromEntries(raw.entries.where(_validRawEntry).take(32)),
       );

  final DeviceInformationSource source;
  final String? manufacturer, model, hardwareModel;
  final String? operatingSystem, operatingSystemVersion;
  final String? softwareVersion, firmwareVersion, buildNumber, protocolVersion;
  final DateTime? identifiedAt;
  final Map<String, String> raw;

  DeviceInformationConfidence get confidence => switch (source) {
    DeviceInformationSource.legacyCache => DeviceInformationConfidence.unknown,
    DeviceInformationSource.discovery ||
    DeviceInformationSource.protocolResponse =>
      DeviceInformationConfidence.reported,
    DeviceInformationSource.authenticatedSession =>
      DeviceInformationConfidence.authenticated,
  };

  /// Older profiles stored only an untyped display value.
  static DeviceSoftwareInformation? fromLegacyMetadata(
    Map<String, String> metadata,
  ) {
    final software = _string(metadata['softwareVersion']);
    if (software == null) {
      return null;
    }
    return DeviceSoftwareInformation(
      source: DeviceInformationSource.legacyCache,
      softwareVersion: software,
      raw: {'softwareVersion': software},
    );
  }

  static DeviceSoftwareInformation? fromJson(Object? value) {
    if (value is! Map<String, Object?>) {
      return null;
    }
    final source = DeviceInformationSource.values
        .where((source) => source.name == value['source'])
        .firstOrNull;
    if (source == null) {
      return null;
    }
    final date = _string(value['identifiedAt']);
    return DeviceSoftwareInformation(
      source: source,
      manufacturer: _string(value['manufacturer']),
      model: _string(value['model']),
      hardwareModel: _string(value['hardwareModel']),
      operatingSystem: _string(value['operatingSystem']),
      operatingSystemVersion: _string(value['operatingSystemVersion']),
      softwareVersion: _string(value['softwareVersion']),
      firmwareVersion: _string(value['firmwareVersion']),
      buildNumber: _string(value['buildNumber']),
      protocolVersion: _string(value['protocolVersion']),
      identifiedAt: date == null ? null : DateTime.tryParse(date),
      raw: _raw(value['raw']),
    );
  }

  Map<String, Object?> toJson() => {
    'source': source.name,
    if (manufacturer != null) 'manufacturer': manufacturer,
    if (model != null) 'model': model,
    if (hardwareModel != null) 'hardwareModel': hardwareModel,
    if (operatingSystem != null) 'operatingSystem': operatingSystem,
    if (operatingSystemVersion != null)
      'operatingSystemVersion': operatingSystemVersion,
    if (softwareVersion != null) 'softwareVersion': softwareVersion,
    if (firmwareVersion != null) 'firmwareVersion': firmwareVersion,
    if (buildNumber != null) 'buildNumber': buildNumber,
    if (protocolVersion != null) 'protocolVersion': protocolVersion,
    if (identifiedAt != null) 'identifiedAt': identifiedAt!.toIso8601String(),
    if (raw.isNotEmpty) 'raw': raw,
  };

  static Map<String, String> _raw(Object? value) =>
      value is Map<String, Object?>
      ? {
          for (final entry in value.entries)
            if (entry.value is String) entry.key: entry.value as String,
        }
      : const {};

  static bool _validRawEntry(MapEntry<String, String> entry) =>
      _string(entry.key) != null && _string(entry.value) != null;

  static String? _string(Object? value) =>
      value is String && value.length <= 256 && value.trim().isNotEmpty
      ? value
      : null;
}
