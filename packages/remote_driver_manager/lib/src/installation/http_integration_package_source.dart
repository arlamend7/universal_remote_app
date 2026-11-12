import 'dart:typed_data';

import '../catalog/catalog_integration.dart';
import '../distribution/driver_http_source.dart';
import 'integration_package_source.dart';

/// Downloads immutable `packages/objects/<sha256>/driver.zip` objects.
final class HttpIntegrationPackageSource implements IntegrationPackageSource {
  HttpIntegrationPackageSource(this._source);

  final DriverHttpSource _source;

  @override
  String get name => 'catalog';

  @override
  Future<Uint8List?> fetch(
    CatalogIntegration entry, {
    Future<void>? cancelled,
    void Function(int bytes)? onBytes,
  }) async {
    final response = await _source.read(
      entry.package,
      maximum: entry.size,
      cancelled: cancelled,
      onBytes: onBytes,
    );
    return response.bytes;
  }
}
