import 'dart:convert';
import 'dart:typed_data';

import 'package:remote_core/remote_core.dart';

/// One integration in a signed catalog: stable identity, compatibility
/// summary and the immutable, hash-addressed package object to install.
final class CatalogIntegration {
  CatalogIntegration._({
    required this.identity,
    required this.name,
    required this.manufacturer,
    required this.platform,
    required this.engine,
    required this.channel,
    required this.lastUpdatedAt,
    required this.runtime,
    required this.compatibility,
    required this.profiles,
    required this.capabilities,
    required this.conditionalCapabilities,
    required this.discovery,
    required this.package,
    required this.sha256,
    required this.size,
    required Uint8List signature,
    required this.replaces,
  }) : _signature = signature;

  factory CatalogIntegration.fromJson(Object? value) {
    final json = IntegrationJson.object(value, 'integration');
    IntegrationJson.keys(json, _fields, required: _required);
    final sha = json['sha256'];
    if (sha is! String || _hash.firstMatch(sha)?.end != sha.length) {
      throw const FormatException('Invalid integration package hash.');
    }
    if (json['package'] != objectPath(sha)) {
      throw const FormatException(
        'Integration packages must reference their immutable object.',
      );
    }
    final signature = json['signature'];
    if (signature is! String || signature.isEmpty || signature.length > 512) {
      throw const FormatException('Invalid integration package signature.');
    }
    final capabilities = IntegrationJson.list(
      json,
      'capabilities',
    ).map(parseRemoteCapability).toSet();
    final conditional = IntegrationJson.list(
      json,
      'conditionalCapabilities',
    ).map(parseRemoteCapability).toSet();
    if (!capabilities.containsAll(conditional)) {
      throw const FormatException('Conditional capability is not declared.');
    }
    return CatalogIntegration._(
      identity: IntegrationIdentity(
        integrationId: IntegrationJson.identifier(json, 'id'),
        providerId: IntegrationJson.identifier(json, 'providerId'),
      ),
      name: IntegrationJson.label(json, 'name'),
      manufacturer: IntegrationJson.label(json, 'manufacturer'),
      platform: IntegrationJson.label(json, 'platform'),
      engine: IntegrationJson.identifier(json, 'engine'),
      channel: IntegrationChannel.parse(json['channel']),
      lastUpdatedAt: IntegrationJson.timestamp(
        json['lastUpdatedAt'],
        'lastUpdatedAt',
      ),
      runtime: RuntimeRequirement.fromJson(json['requiredRuntime']),
      compatibility: IntegrationCompatibility.fromJson(
        IntegrationJson.object(json['compatibility'], 'compatibility'),
      ),
      profiles: List.unmodifiable(
        IntegrationJson.list(
          json,
          'profiles',
          maximum: 64,
        ).map(CompatibilityProfile.fromJson),
      ),
      capabilities: Set.unmodifiable(capabilities),
      conditionalCapabilities: Set.unmodifiable(conditional),
      discovery: _discovery(json['discovery']),
      package: objectPath(sha),
      sha256: sha,
      size: IntegrationJson.integer(
        json,
        'size',
        minimum: 1,
        maximum: maxBytes,
      ),
      signature: base64Decode(signature),
      replaces: Set.unmodifiable(IntegrationJson.labels(json, 'replaces')),
    );
  }

  static const maxBytes = 4 * 1024 * 1024;
  static final _hash = RegExp(r'^[0-9a-f]{64}$');
  static const _required = {
    'id',
    'providerId',
    'name',
    'manufacturer',
    'platform',
    'engine',
    'channel',
    'lastUpdatedAt',
    'requiredRuntime',
    'compatibility',
    'profiles',
    'capabilities',
    'package',
    'sha256',
    'size',
    'signature',
  };
  static const _fields = {
    ..._required,
    'conditionalCapabilities',
    'discovery',
    'replaces',
  };

  /// Immutable delivery path: a new content hash is always a new object.
  static String objectPath(String sha256) =>
      'packages/objects/$sha256/driver.zip';

  final IntegrationIdentity identity;
  final String name, manufacturer, platform, engine;
  final IntegrationChannel channel;
  final DateTime lastUpdatedAt;
  final RuntimeRequirement runtime;
  final IntegrationCompatibility compatibility;
  final List<CompatibilityProfile> profiles;
  final Set<RemoteCapability> capabilities;
  final Set<RemoteCapability> conditionalCapabilities;

  /// Network evidence used to match devices before the package is installed;
  /// interpreted by the runtime's discovery rules.
  final Map<String, Object?>? discovery;
  final String package, sha256;
  final int size;
  final Uint8List _signature;

  /// Retired driver family IDs whose device assignments migrate here.
  final Set<String> replaces;

  String get id => identity.integrationId;
  String get providerId => identity.providerId;
  bool get development => channel == IntegrationChannel.development;
  Uint8List get signature => Uint8List.fromList(_signature);

  static Map<String, Object?>? _discovery(Object? value) {
    if (value == null) {
      return null;
    }
    final json = IntegrationJson.object(value, 'discovery');
    if (jsonEncode(json).length > 16 * 1024) {
      throw const FormatException('Integration discovery rules are too large.');
    }
    return Map.unmodifiable(json);
  }
}
