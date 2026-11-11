import '../device.dart';

/// Device version evidence stays opaque until the manager applies the
/// comparison strategy for the platform.
final class DriverCompatibility {
  DriverCompatibility({
    required this.id,
    required this.version,
    required Iterable<String> models,
    this.osVersion,
    this.firmwareVersion,
    this.hardwareModel,
    this.softwareVersion,
    this.buildNumber,
    this.protocolVersion,
    Iterable<RemoteCapability> disabledCapabilities = const [],
  }) : models = Set.unmodifiable(models),
       disabledCapabilities = Set.unmodifiable(disabledCapabilities) {
    if (_idFormat.firstMatch(id)?.end != id.length ||
        version < 1 ||
        version > 999999999 ||
        this.models.any((model) => !_validLabel(model)) ||
        ![
          osVersion,
          firmwareVersion,
          hardwareModel,
          softwareVersion,
          buildNumber,
          protocolVersion,
        ].whereType<String>().every(_validLabel)) {
      throw const FormatException('Invalid driver compatibility profile.');
    }
  }

  static final _idFormat = RegExp(r'^[a-z][a-z0-9_-]{0,79}$');

  final String id;
  final int version;
  final Set<String> models;
  final String? osVersion, firmwareVersion;
  final String? hardwareModel, softwareVersion, buildNumber, protocolVersion;
  final Set<RemoteCapability> disabledCapabilities;

  static bool _validLabel(String value) =>
      value.isNotEmpty && value.length <= 128 && value.trim() == value;
}
