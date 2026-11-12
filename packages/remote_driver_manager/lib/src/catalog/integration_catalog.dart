import 'package:remote_core/remote_core.dart';

import '../distribution/driver_signature_verifier.dart';
import 'catalog_integration.dart';
import 'signed_catalog_envelope.dart';

/// The authoritative, signed index of published integrations (schema 2).
///
/// [revision] is monotonic: clients reject a lower revision, and the same
/// revision with different content, so a mirror cannot roll them back.
final class IntegrationCatalog {
  IntegrationCatalog._(
    this.revision,
    this.publishedAt,
    this.keyId,
    this.integrations,
  );

  static const schemaVersion = 2;

  final int revision;
  final DateTime publishedAt;
  final String keyId;
  final List<CatalogIntegration> integrations;

  static Future<IntegrationCatalog> verify(
    String envelope,
    DriverSignatureVerifier verifySignature,
  ) async {
    final opened = await SignedCatalogEnvelope.open(envelope, verifySignature);
    return decode(opened.decodePayload(), opened.keyId);
  }

  /// Decodes an already verified payload.
  static IntegrationCatalog decode(Object? value, String keyId) {
    final json = IntegrationJson.object(value, 'catalog');
    IntegrationJson.keys(
      json,
      const {'schemaVersion', 'revision', 'publishedAt', 'integrations'},
      required: const {
        'schemaVersion',
        'revision',
        'publishedAt',
        'integrations',
      },
    );
    if (json['schemaVersion'] != schemaVersion) {
      throw const FormatException('Unsupported integration catalog schema.');
    }
    final integrations = IntegrationJson.list(
      json,
      'integrations',
      maximum: 1024,
    ).map(CatalogIntegration.fromJson).toList();
    final ids = integrations.map((integration) => integration.id).toSet();
    if (ids.length != integrations.length) {
      throw const FormatException('Duplicate integration ID in catalog.');
    }
    return IntegrationCatalog._(
      IntegrationJson.integer(json, 'revision', minimum: 1),
      IntegrationJson.timestamp(json['publishedAt'], 'publishedAt'),
      keyId,
      List.unmodifiable(integrations),
    );
  }

  CatalogIntegration? integration(String id) =>
      integrations.where((integration) => integration.id == id).firstOrNull;
}
