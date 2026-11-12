import 'dart:convert';
import 'dart:typed_data';

import '../catalog/catalog_integration.dart';
import '../distribution/driver_signature_verifier.dart';
import 'integration_package.dart';
import 'integration_validator.dart';
import 'verified_object.dart';

/// Authenticates downloaded or seeded bytes against their catalog entry.
///
/// Order matters: size, hash and signature are checked before the ZIP is
/// parsed, and the parsed manifest must agree with the signed metadata.
final class PackageVerifier {
  PackageVerifier(this._verifySignature, {IntegrationValidator? validate})
    : _validate = validate;

  final DriverSignatureVerifier _verifySignature;
  final IntegrationValidator? _validate;

  Future<(IntegrationPackage, VerifiedObject)> verify(
    CatalogIntegration entry,
    Uint8List bytes, {
    required String keyId,
    required int catalogRevision,
    required String source,
    required DateTime now,
  }) async {
    if (bytes.length != entry.size || sha256Of(bytes) != entry.sha256) {
      throw const FormatException('Integration package hash mismatch.');
    }
    if (!await _verifySignature(keyId, bytes, entry.signature)) {
      throw const FormatException('Integration package signature is invalid.');
    }
    final package = IntegrationPackage.read(bytes);
    _matches(entry, package);
    _validate?.call(package);
    return (
      package,
      VerifiedObject(
        sha256: entry.sha256,
        identity: entry.identity,
        lastUpdatedAt: entry.lastUpdatedAt,
        size: entry.size,
        verifiedAt: now.toUtc(),
        source: source,
        catalogRevision: catalogRevision,
        keyId: keyId,
      ),
    );
  }

  static void _matches(CatalogIntegration entry, IntegrationPackage package) {
    final manifest = package.manifest;
    final same =
        manifest.identity == entry.identity &&
        manifest.lastUpdatedAt == entry.lastUpdatedAt &&
        manifest.engine == entry.engine &&
        _json(manifest.runtime.toJson()) == _json(entry.runtime.toJson()) &&
        _json(manifest.compatibility.toJson()) ==
            _json(entry.compatibility.toJson()) &&
        manifest.capabilities.length == entry.capabilities.length &&
        manifest.capabilities.containsAll(entry.capabilities);
    if (!same) {
      throw const FormatException(
        'Integration package does not match its signed catalog entry.',
      );
    }
  }

  static String _json(Object? value) => jsonEncode(value);
}
