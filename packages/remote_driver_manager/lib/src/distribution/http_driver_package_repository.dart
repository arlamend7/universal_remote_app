import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:remote_core/remote_core.dart';

import '../lifecycle/driver_package.dart';
import '../lifecycle/driver_package_repository.dart';
import 'driver_catalog_repository.dart';
import 'driver_http_source.dart';
import 'driver_signature_verifier.dart';
import 'stored_driver_zip.dart';

final class HttpDriverPackageRepository implements DriverPackageRepository {
  HttpDriverPackageRepository(
    this._source,
    this._catalog,
    this._verify, {
    bool includeDevelopment = false,
  }) : _includeDevelopment = includeDevelopment;

  final DriverHttpSource _source;
  final DriverCatalogRepository _catalog;
  final DriverSignatureVerifier _verify;
  final bool _includeDevelopment;
  final _downloading =
      <(String, String, DriverVersion), Future<DriverPackage>>{};

  @override
  Future<DriverPackage> fetch(DriverIdentity identity) {
    final key = (identity.id, identity.providerId, identity.version);
    return _downloading.putIfAbsent(
      key,
      () => _fetch(identity).whenComplete(() {
        _downloading.remove(key);
      }),
    );
  }

  Future<DriverPackage> _fetch(DriverIdentity identity) async {
    final catalog = await _catalog.cached() ?? await _catalog.refresh();
    final release = catalog.releases.where((release) {
      final candidate = release.manifest.identity;
      return candidate.id == identity.id &&
          candidate.providerId == identity.providerId &&
          candidate.version == identity.version &&
          (_includeDevelopment || !release.development);
    }).firstOrNull;
    if (release == null) {
      throw const RemoteException(
        'driverUnavailable',
        'The driver release is unavailable.',
      );
    }
    final response = await _source.read(release.path, maximum: release.size);
    final bytes = response.bytes!;
    if (bytes.length != release.size ||
        sha256.convert(bytes).toString() != release.sha256 ||
        !await _verify(catalog.keyId, bytes, release.signature)) {
      throw const FormatException('Driver package authenticity check failed.');
    }
    final package = DriverPackage(StoredDriverZip(bytes).read());
    if (jsonEncode(package.bundle.manifest.toJson()) !=
        jsonEncode(release.manifest.toJson())) {
      throw const FormatException(
        'Driver package manifest differs from its release.',
      );
    }
    final discovery = release.discovery;
    if (discovery != null &&
        jsonEncode(package.bundle.discovery.toJson()) !=
            jsonEncode(discovery.toJson())) {
      throw const FormatException(
        'Driver discovery rules differ from its release.',
      );
    }
    return package;
  }
}
