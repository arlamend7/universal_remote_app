import 'package:remote_core/remote_core.dart';

import 'address_policy.dart';
import 'discovery_identity_rule.dart';
import 'endpoint_template.dart';

/// `discovery.json`: how network evidence identifies a device of this
/// provider family and how saved or typed addresses are verified.
final class DiscoveryRules {
  DiscoveryRules._(
    this.json, {
    required this.label,
    required this.protocol,
    required this.service,
    required this.identity,
    required this.endpoint,
    required this.category,
  });

  factory DiscoveryRules.fromJson(Map<String, Object?> json) {
    IntegrationJson.keys(json, _fields, required: _required);
    final protocol = DiscoveryProtocol.values
        .where((value) => value.name == json['protocol'])
        .firstOrNull;
    final service = json['service'];
    if (protocol == null ||
        protocol == DiscoveryProtocol.unicast ||
        service is! String ||
        !_service.hasMatch(service)) {
      throw const FormatException('Invalid discovery protocol or service.');
    }
    final rules = DiscoveryRules._(
      Map.unmodifiable(json),
      label: IntegrationJson.label(json, 'label'),
      protocol: protocol,
      service: service,
      identity: DiscoveryIdentityRule.fromJson(json['identity']),
      endpoint: EndpointTemplate.fromJson(json['endpoint']),
      category: _category(json['category']),
    );
    rules._validate();
    return rules;
  }

  static const _required = {
    'label',
    'protocol',
    'service',
    'identity',
    'endpoint',
  };
  static const _fields = {
    ..._required,
    'category',
    'manufacturer',
    'requireServiceHeader',
    'port',
    'address',
    'location',
    'name',
    'model',
    'copyMetadata',
    'metadata',
    'addressProbe',
    'unicastProbe',
  };
  static final _service = RegExp(r'^[a-zA-Z0-9_:.+/-]{1,128}$');

  final Map<String, Object?> json;
  final String label;
  final DiscoveryProtocol protocol;
  final String service;
  final DiscoveryIdentityRule identity;
  final EndpointTemplate endpoint;
  final DeviceCategory category;

  String? get manufacturer => json['manufacturer'] as String?;
  bool get requireServiceHeader => json['requireServiceHeader'] == true;
  int? get port => json['port'] as int?;
  AddressPolicy? get address =>
      json['address'] == null ? null : AddressPolicy.parse(json['address']);
  bool get requireLocation => json['location'] == 'endpoint';
  bool get copyMetadata => json['copyMetadata'] == true;
  String? get modelMetadata => json['model'] as String?;
  Map<String, Object?> get name =>
      (json['name'] as Map<String, Object?>?) ?? const {};
  Map<String, String> get metadata =>
      ((json['metadata'] as Map<String, Object?>?) ?? const {})
          .cast<String, String>();
  Map<String, Object?>? get addressProbe =>
      json['addressProbe'] as Map<String, Object?>?;
  Map<String, Object?>? get unicastProbe =>
      json['unicastProbe'] as Map<String, Object?>?;

  DiscoveryRequirements get requirements => DiscoveryRequirements({
    protocol: {service},
  });

  void _validate() {
    final port = json['port'];
    if (port != null && (port is! int || port < 1 || port > 65535)) {
      throw const FormatException('Invalid discovery port.');
    }
    for (final key in const ['manufacturer', 'model']) {
      IntegrationJson.optionalLabel(json, key);
    }
    final metadata = IntegrationJson.object(
      json['metadata'] ?? const <String, Object?>{},
      'metadata',
    );
    if (metadata.length > 8 ||
        !metadata.values.every(
          (value) => value is String && value.length < 128,
        )) {
      throw const FormatException('Invalid discovery metadata templates.');
    }
    _probe(addressProbe, const {'ssdp', 'peer-identity-pair', 'ecp-serial'});
    _probe(unicastProbe, const {'certificate', 'peer-identity', 'ecp-serial'});
    address;
  }

  static void _probe(Map<String, Object?>? probe, Set<String> kinds) {
    if (probe == null) {
      return;
    }
    IntegrationJson.keys(
      probe,
      const {'kind', 'service', 'ports', 'metadata', 'fallbackMetadata'},
      required: const {'kind'},
    );
    if (!kinds.contains(probe['kind'])) {
      throw const FormatException('Unsupported discovery probe.');
    }
  }

  static DeviceCategory _category(Object? value) =>
      DeviceCategory.parse(value ?? 'television');
}
