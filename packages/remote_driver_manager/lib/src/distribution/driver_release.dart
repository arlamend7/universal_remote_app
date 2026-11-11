import 'dart:convert';
import 'dart:typed_data';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';

final class DriverRelease {
  DriverRelease._(
    this.manifest,
    this.path,
    this.size,
    this.sha256,
    this._signature,
    this.development,
    this.discovery,
    this.publishedAt,
    this.notes,
  );

  factory DriverRelease.fromJson(Object? value) {
    if (value is! Map<String, Object?> ||
        value.keys.any((key) => !_fields.contains(key))) {
      throw const FormatException('Invalid driver release.');
    }
    final manifestJson = value['manifest'];
    if (manifestJson is! Map<String, Object?>) {
      throw const FormatException('Invalid release manifest.');
    }
    final manifest = DriverManifest.fromJson(manifestJson);
    final identity = manifest.identity;
    final path = 'packages/${identity.id}/${identity.version}/driver.zip';
    final size = value['size'];
    final hash = value['sha256'];
    final signature = value['signature'];
    final channel = value['channel'];
    final discovery = value['discovery'];
    final published = value['publishedAt'];
    final notes = value['notes'];
    if ((value.containsKey('discovery') &&
            discovery is! Map<String, Object?>) ||
        (published != null &&
            (published is! String ||
                !published.endsWith('Z') ||
                DateTime.tryParse(published) == null)) ||
        (notes != null && (notes is! String || notes.length > 4096)) ||
        value['package'] != path ||
        size is! int ||
        size < 1 ||
        size > maxBytes ||
        hash is! String ||
        _hash.firstMatch(hash)?.end != hash.length ||
        signature is! String ||
        signature.isEmpty ||
        signature.length > 512 ||
        (channel != 'stable' && channel != 'development')) {
      throw const FormatException('Invalid driver release metadata.');
    }
    return DriverRelease._(
      manifest,
      path,
      size,
      hash,
      base64Decode(signature),
      channel == 'development',
      discovery is Map<String, Object?>
          ? DriverDiscoveryRules.fromJson(discovery)
          : null,
      published is String ? DateTime.parse(published) : null,
      notes as String?,
    );
  }

  static const _fields = {
    'manifest',
    'package',
    'size',
    'sha256',
    'signature',
    'channel',
    'discovery',
    'publishedAt',
    'notes',
  };
  static const maxBytes = 4 * 1024 * 1024;
  static final _hash = RegExp(r'^[0-9a-f]{64}$');

  final DriverManifest manifest;
  final DriverDiscoveryRules? discovery;
  final DateTime? publishedAt;
  final String? notes;
  final String path, sha256;
  final int size;
  final Uint8List _signature;
  final bool development;

  Uint8List get signature => Uint8List.fromList(_signature);
}
