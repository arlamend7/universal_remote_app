import 'dart:convert';
import 'dart:io';

import 'package:remote_core/remote_core.dart';

import '../catalog/integration_catalog.dart';
import '../catalog/signed_catalog_envelope.dart';
import '../distribution/driver_http_source.dart';
import '../distribution/driver_signature_verifier.dart';
import 'atomic_json_file.dart';

/// Fetches `v2/catalog.json`, rejects rollback, and keeps the exact signed
/// envelope in `catalog-cache.json` for offline use.
final class IntegrationCatalogRepository {
  IntegrationCatalogRepository(
    this._source,
    Directory root,
    this._verify, {
    DateTime Function()? now,
  }) : _cache = AtomicJsonFile(File('${root.path}/catalog-cache.json')),
       _now = now ?? (() => DateTime.now().toUtc());

  static const path = 'v2/catalog.json';

  final DriverHttpSource? _source;
  final AtomicJsonFile _cache;
  final DriverSignatureVerifier _verify;
  final DateTime Function() _now;
  Future<IntegrationCatalog>? _refreshing;

  /// The verified cached catalog. Never touches the network.
  Future<IntegrationCatalog?> cached() async {
    final envelope = (await _cache.read())?['envelope'];
    if (envelope is! String) {
      return null;
    }
    return IntegrationCatalog.verify(envelope, _verify);
  }

  Future<DateTime?> lastChecked() async {
    final value = (await _cache.read())?['checkedAt'];
    return value == null ? null : IntegrationJson.timestamp(value, 'checkedAt');
  }

  /// Accepts an envelope from a trusted local source such as the app seed.
  /// It never replaces a newer cached revision.
  Future<IntegrationCatalog> adopt(String envelope) async {
    final catalog = await IntegrationCatalog.verify(envelope, _verify);
    final old = await cached();
    if (old != null && old.revision >= catalog.revision) {
      return old;
    }
    await _save(envelope, null, checked: false);
    return catalog;
  }

  Future<IntegrationCatalog> refresh() {
    final active = _refreshing;
    if (active != null) {
      return active;
    }
    final request = _refresh().whenComplete(() => _refreshing = null);
    return _refreshing = request;
  }

  Future<IntegrationCatalog> _refresh() async {
    final source = _source;
    if (source == null) {
      throw const RemoteException(
        'driverDistribution',
        'Driver downloads are not configured for this build.',
      );
    }
    final saved = await _cache.read();
    final savedEnvelope = saved?['envelope'] as String?;
    final old = savedEnvelope == null
        ? null
        : await IntegrationCatalog.verify(savedEnvelope, _verify);
    final response = await source.read(
      path,
      maximum: SignedCatalogEnvelope.maximumBytes,
      etag: saved?['etag'] as String?,
    );
    final bytes = response.bytes;
    if (bytes == null && old != null) {
      await _save(savedEnvelope!, response.etag);
      return old;
    }
    final envelope = utf8.decode(bytes!);
    final catalog = await IntegrationCatalog.verify(envelope, _verify);
    if (old != null &&
        (catalog.revision < old.revision ||
            (catalog.revision == old.revision && envelope != savedEnvelope))) {
      throw const FormatException(
        'Integration catalog rollback or revision conflict.',
      );
    }
    await _save(envelope, response.etag);
    return catalog;
  }

  Future<void> _save(String envelope, String? etag, {bool checked = true}) =>
      _cache.write({
        'envelope': envelope,
        'etag': ?etag,
        if (checked) 'checkedAt': IntegrationJson.formatTimestamp(_now()),
      });
}
