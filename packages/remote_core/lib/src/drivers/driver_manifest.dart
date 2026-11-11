import '../device.dart';
import 'driver_compatibility.dart';
import 'driver_identity.dart';
import 'driver_operation.dart';
import 'driver_runtime_requirements.dart';
import 'driver_version.dart';

/// Package metadata. Discovery rules and executable workflows are validated
/// separately by the components responsible for interpreting them.
final class DriverManifest {
  DriverManifest({
    required this.identity,
    required this.name,
    required this.manufacturer,
    required this.platform,
    required this.runtime,
    required Iterable<RemoteCapability> capabilities,
    required Iterable<DriverCompatibility> compatibility,
  }) : capabilities = Set.unmodifiable(capabilities),
       compatibility = List.unmodifiable(compatibility) {
    if (![name, manufacturer, platform].every(_validLabel) ||
        this.compatibility.isEmpty ||
        this.compatibility.map((profile) => profile.id).toSet().length !=
            this.compatibility.length ||
        this.compatibility.any(
          (profile) =>
              !this.capabilities.containsAll(profile.disabledCapabilities),
        )) {
      throw const FormatException('Invalid driver manifest metadata.');
    }
  }

  factory DriverManifest.fromJson(Map<String, Object?> json) {
    _expectKeys(json, _keys);
    final schema = json['schemaVersion'];
    if (schema is! int || schema != schemaVersion) {
      throw const FormatException('Unsupported driver manifest schema.');
    }
    return DriverManifest(
      identity: DriverIdentity(
        id: _string(json, 'id'),
        providerId: _string(json, 'providerId'),
        version: DriverVersion.parse(_string(json, 'version')),
      ),
      name: _string(json, 'name'),
      manufacturer: _string(json, 'manufacturer'),
      platform: _string(json, 'platform'),
      runtime: DriverRuntimeRequirements.parse(
        _string(json, 'requiredRuntime'),
        _list(json, 'operations').map(_operation),
      ),
      capabilities: _list(json, 'capabilities').map(_capability),
      compatibility: _list(json, 'compatibility').map(_profile),
    );
  }

  static const schemaVersion = 1;
  static const _keys = {
    'schemaVersion',
    'id',
    'providerId',
    'version',
    'name',
    'manufacturer',
    'platform',
    'requiredRuntime',
    'operations',
    'capabilities',
    'compatibility',
  };

  final DriverIdentity identity;
  final String name, manufacturer, platform;
  final DriverRuntimeRequirements runtime;
  final Set<RemoteCapability> capabilities;
  final List<DriverCompatibility> compatibility;

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'id': identity.id,
    'providerId': identity.providerId,
    'version': identity.version.toString(),
    'name': name,
    'manufacturer': manufacturer,
    'platform': platform,
    'requiredRuntime': runtime.constraint,
    'operations': runtime.operations.map((operation) => operation.id).toList(),
    'capabilities': capabilities.map((capability) => capability.name).toList(),
    'compatibility': compatibility.map(_profileJson).toList(),
  };

  static DriverOperation _operation(Object? value) {
    if (value is! String) {
      throw const FormatException('Invalid driver operation ID.');
    }
    return DriverOperation.parse(value);
  }

  static RemoteCapability _capability(Object? value) {
    final capability = RemoteCapability.values
        .where((candidate) => candidate.name == value)
        .firstOrNull;
    if (capability == null) {
      throw const FormatException('Unknown driver capability.');
    }
    return capability;
  }

  static DriverCompatibility _profile(Object? value) {
    if (value is! Map<String, Object?> || value['version'] is! int) {
      throw const FormatException('Invalid driver compatibility profile.');
    }
    _expectKeys(value, {
      'id',
      'version',
      'models',
      'osVersion',
      'firmwareVersion',
      'disabledCapabilities',
    });
    return DriverCompatibility(
      id: _string(value, 'id'),
      version: value['version'] as int,
      models: _list(value, 'models').map(_model),
      osVersion: _optionalString(value, 'osVersion'),
      firmwareVersion: _optionalString(value, 'firmwareVersion'),
      disabledCapabilities: value.containsKey('disabledCapabilities')
          ? _list(value, 'disabledCapabilities').map(_capability)
          : const [],
    );
  }

  static Map<String, Object?> _profileJson(DriverCompatibility profile) => {
    'id': profile.id,
    'version': profile.version,
    'models': profile.models.toList(),
    if (profile.osVersion != null) 'osVersion': profile.osVersion,
    if (profile.firmwareVersion != null)
      'firmwareVersion': profile.firmwareVersion,
    if (profile.disabledCapabilities.isNotEmpty)
      'disabledCapabilities': profile.disabledCapabilities
          .map((capability) => capability.name)
          .toList(),
  };

  static String _model(Object? value) {
    if (value is! String) {
      throw const FormatException('Invalid driver model.');
    }
    return value;
  }

  static void _expectKeys(Map<String, Object?> json, Set<String> keys) {
    if (json.keys.any((key) => !keys.contains(key))) {
      throw const FormatException('Unknown driver metadata field.');
    }
  }

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || !_validLabel(value)) {
      throw FormatException('Invalid driver metadata field: $key.');
    }
    return value;
  }

  static String? _optionalString(Map<String, Object?> json, String key) =>
      json.containsKey(key) ? _string(json, key) : null;

  static List<Object?> _list(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! List<Object?> || value.length > 256) {
      throw FormatException('Invalid driver metadata list: $key.');
    }
    return value;
  }

  static bool _validLabel(String value) =>
      value.isNotEmpty && value.length <= 128 && value.trim() == value;
}
