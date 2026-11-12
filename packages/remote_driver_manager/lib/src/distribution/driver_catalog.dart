import '../catalog/signed_catalog_envelope.dart';
import 'driver_release.dart';
import 'driver_signature_verifier.dart';

final class DriverCatalog {
  DriverCatalog._(this.revision, this.publishedAt, this.keyId, this.releases);

  static const maximumBytes = SignedCatalogEnvelope.maximumBytes;

  final int revision;
  final DateTime publishedAt;
  final String keyId;
  final List<DriverRelease> releases;

  static Future<DriverCatalog> verify(
    String envelope,
    DriverSignatureVerifier verifySignature,
  ) async {
    final opened = await SignedCatalogEnvelope.open(envelope, verifySignature);
    return _decode(opened.decodePayload(), opened.keyId);
  }

  static DriverCatalog _decode(Object? value, String key) {
    if (value is! Map<String, Object?> ||
        value.length != 4 ||
        value['schemaVersion'] is! int ||
        value['schemaVersion'] != 1) {
      throw const FormatException('Unsupported driver catalog schema.');
    }
    final revision = value['revision'];
    final published = value['publishedAt'];
    final releases = value['releases'];
    if (revision is! int ||
        revision < 1 ||
        published is! String ||
        !published.endsWith('Z') ||
        releases is! List<Object?> ||
        releases.length > 1024) {
      throw const FormatException('Invalid driver catalog metadata.');
    }
    final timestamp = DateTime.tryParse(published);
    if (timestamp == null) {
      throw const FormatException('Invalid driver catalog timestamp.');
    }
    final parsed = releases.map(DriverRelease.fromJson).toList();
    if (parsed.map((release) => release.path).toSet().length != parsed.length) {
      throw const FormatException('Duplicate driver release.');
    }
    return DriverCatalog._(revision, timestamp, key, List.unmodifiable(parsed));
  }
}
