import 'dart:convert';

import '../lifecycle/cached_driver_catalog.dart';
import '../lifecycle/driver_package_storage.dart';
import 'driver_catalog.dart';
import 'driver_http_source.dart';
import 'driver_signature_verifier.dart';

final class DriverCatalogRepository {
  DriverCatalogRepository(this._source, this._storage, this._verify);

  final DriverHttpSource _source;
  final DriverPackageStorage _storage;
  final DriverSignatureVerifier _verify;
  Future<DriverCatalog>? _refreshing;

  Future<DriverCatalog?> cached() async {
    final cached = await _storage.readCatalog();
    return cached == null
        ? null
        : DriverCatalog.verify(cached.envelope, _verify);
  }

  Future<DriverCatalog> refresh() {
    final active = _refreshing;
    if (active != null) {
      return active;
    }
    final request = _refresh().whenComplete(() => _refreshing = null);
    return _refreshing = request;
  }

  Future<DriverCatalog> _refresh() async {
    final saved = await _storage.readCatalog();
    final old = saved == null
        ? null
        : await DriverCatalog.verify(saved.envelope, _verify);
    final response = await _source.read(
      'catalog.json',
      maximum: DriverCatalog.maximumBytes,
      etag: saved?.etag,
    );
    final bytes = response.bytes;
    if (bytes == null) {
      return old!;
    }
    final envelope = utf8.decode(bytes);
    final catalog = await DriverCatalog.verify(envelope, _verify);
    if (old != null &&
        (catalog.revision < old.revision ||
            (catalog.revision == old.revision &&
                envelope != saved!.envelope))) {
      throw const FormatException(
        'Driver catalog rollback or revision conflict.',
      );
    }
    await _storage.writeCatalog(
      CachedDriverCatalog(envelope, etag: response.etag),
    );
    return catalog;
  }
}
