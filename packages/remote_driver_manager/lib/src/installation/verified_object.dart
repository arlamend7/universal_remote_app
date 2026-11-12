import 'package:remote_core/remote_core.dart';

/// Provenance stored beside an installed package object. The hash is the
/// verified catalog value; it is never read from the package itself.
final class VerifiedObject {
  const VerifiedObject({
    required this.sha256,
    required this.identity,
    required this.lastUpdatedAt,
    required this.size,
    required this.verifiedAt,
    required this.source,
    this.catalogRevision,
    this.keyId,
  });

  factory VerifiedObject.fromJson(Map<String, Object?> json) {
    IntegrationJson.keys(json, _fields, required: _required);
    final revision = json['catalogRevision'];
    final key = json['keyId'];
    return VerifiedObject(
      sha256: _hash(json['sha256']),
      identity: IntegrationIdentity(
        integrationId: IntegrationJson.identifier(json, 'integrationId'),
        providerId: IntegrationJson.identifier(json, 'providerId'),
      ),
      lastUpdatedAt: IntegrationJson.timestamp(
        json['lastUpdatedAt'],
        'lastUpdatedAt',
      ),
      size: IntegrationJson.integer(json, 'size', minimum: 1),
      verifiedAt: IntegrationJson.timestamp(json['verifiedAt'], 'verifiedAt'),
      source: IntegrationJson.label(json, 'source'),
      catalogRevision: revision is int ? revision : null,
      keyId: key is String ? key : null,
    );
  }

  static const _required = {
    'sha256',
    'integrationId',
    'providerId',
    'lastUpdatedAt',
    'size',
    'verifiedAt',
    'source',
  };
  static const _fields = {..._required, 'catalogRevision', 'keyId'};
  static final _format = RegExp(r'^[0-9a-f]{64}$');

  final String sha256;
  final IntegrationIdentity identity;
  final DateTime lastUpdatedAt;
  final int size;
  final DateTime verifiedAt;

  /// `catalog`, `seed` or `local` — where the verified bytes came from.
  final String source;
  final int? catalogRevision;
  final String? keyId;

  Map<String, Object?> toJson() => {
    'sha256': sha256,
    'integrationId': identity.integrationId,
    'providerId': identity.providerId,
    'lastUpdatedAt': IntegrationJson.formatTimestamp(lastUpdatedAt),
    'size': size,
    'verifiedAt': IntegrationJson.formatTimestamp(verifiedAt),
    'source': source,
    if (catalogRevision != null) 'catalogRevision': catalogRevision,
    if (keyId != null) 'keyId': keyId,
  };

  static String _hash(Object? value) {
    if (value is! String || _format.firstMatch(value)?.end != value.length) {
      throw const FormatException('Invalid stored package hash.');
    }
    return value;
  }

  static bool isHash(String value) =>
      _format.firstMatch(value)?.end == value.length;
}
