import 'package:remote_core/remote_core.dart';

import '../discovery/address_policy.dart';
import '../discovery/endpoint_template.dart';

/// `device.json#setup`: how a device is created from a typed address.
final class ManualSetupRules {
  ManualSetupRules._(
    this.json, {
    required this.label,
    required this.address,
    required this.endpoint,
    required this.category,
    this.legacyEndpoint,
  });

  factory ManualSetupRules.fromJson(Object? value) {
    final json = IntegrationJson.object(value, 'setup');
    IntegrationJson.keys(
      json,
      _fields,
      required: const {'label', 'address', 'endpoint'},
    );
    final legacy = json['legacyEndpoint'];
    final fields = IntegrationJson.labels(json, 'fields');
    if (!_supportedFields.containsAll(fields)) {
      throw const FormatException('Unknown manual setup field.');
    }
    final messages = IntegrationJson.object(
      json['messages'] ?? const <String, Object?>{},
      'messages',
    );
    if (!messages.values.every(
      (value) => value is String && value.length < 256,
    )) {
      throw const FormatException('Invalid manual setup message.');
    }
    final category = DeviceCategory.values.where(
      (candidate) => candidate.name == (json['category'] ?? 'television'),
    );
    if (category.isEmpty) {
      throw const FormatException('Unknown device category.');
    }
    return ManualSetupRules._(
      Map.unmodifiable(json),
      label: IntegrationJson.label(json, 'label'),
      address: AddressPolicy.parse(json['address']),
      endpoint: EndpointTemplate.fromJson(json['endpoint']),
      legacyEndpoint: legacy == null ? null : EndpointTemplate.fromJson(legacy),
      category: category.single,
    );
  }

  static const _fields = {
    'label',
    'advanced',
    'address',
    'endpoint',
    'legacyEndpoint',
    'defaultName',
    'requireName',
    'idTemplate',
    'manufacturer',
    'category',
    'metadata',
    'fields',
    'insecureMetadata',
    'messages',
  };
  static const _supportedFields = {'certificate', 'mac', 'broadcast'};

  final Map<String, Object?> json;
  final String label;
  final AddressPolicy address;
  final EndpointTemplate endpoint;
  final EndpointTemplate? legacyEndpoint;
  final DeviceCategory category;

  bool get advanced => json['advanced'] == true;
  bool get requireName => json['requireName'] == true;
  String get defaultName => (json['defaultName'] as String?) ?? label;
  String? get manufacturer => json['manufacturer'] as String?;
  String? get idTemplate => json['idTemplate'] as String?;
  String? get insecureMetadata => json['insecureMetadata'] as String?;
  Set<String> get fields =>
      ((json['fields'] as List?) ?? const []).cast<String>().toSet();
  Map<String, String> get metadata =>
      ((json['metadata'] as Map?) ?? const {}).cast<String, String>();

  /// Declared when typed legacy/insecure options must be refused.
  String? get secureOnlyMessage =>
      (json['messages'] as Map?)?['secureOnly'] as String?;

  String message(String key, String fallback) =>
      ((json['messages'] as Map?)?[key] as String?) ?? fallback;
}
