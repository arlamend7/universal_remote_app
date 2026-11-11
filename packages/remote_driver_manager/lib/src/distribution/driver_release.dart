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
  );

  factory DriverRelease.fromJson(Object? value) {
    if (value is! Map<String, Object?> ||
        (value.length != 6 && value.length != 7)) {
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
    if ((value.length == 7 && discovery is! Map<String, Object?>) ||
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
    );
  }

  static const maxBytes = 4 * 1024 * 1024;
  static final _hash = RegExp(r'^[0-9a-f]{64}$');

  final DriverManifest manifest;
  final DriverDiscoveryRules? discovery;
  final String path, sha256;
  final int size;
  final Uint8List _signature;
  final bool development;

  Uint8List get signature => Uint8List.fromList(_signature);
}
