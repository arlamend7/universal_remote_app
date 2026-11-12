import 'dart:typed_data';

import '../catalog/catalog_integration.dart';

/// Supplies the bytes of a catalog entry's package object. Bytes are always
/// verified by [PackageVerifier] before installation.
abstract interface class IntegrationPackageSource {
  /// Short provenance label stored with installed objects.
  String get name;

  Future<Uint8List?> fetch(
    CatalogIntegration entry, {
    Future<void>? cancelled,
    void Function(int bytes)? onBytes,
  });
}
