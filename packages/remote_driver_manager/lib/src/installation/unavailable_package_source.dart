import 'dart:typed_data';

import '../catalog/catalog_integration.dart';
import 'integration_package_source.dart';

/// Used when this build has no driver repository configured.
final class UnavailablePackageSource implements IntegrationPackageSource {
  const UnavailablePackageSource();

  @override
  String get name => 'unavailable';

  @override
  Future<Uint8List?> fetch(
    CatalogIntegration entry, {
    Future<void>? cancelled,
    void Function(int bytes)? onBytes,
  }) async => null;
}
