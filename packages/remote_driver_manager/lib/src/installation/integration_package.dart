import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:remote_core/remote_core.dart';

import '../distribution/stored_driver_zip.dart';

/// The immutable files of one integration generation, identified by the
/// SHA-256 of its exact ZIP bytes. The manifest never contains its own hash.
final class IntegrationPackage {
  IntegrationPackage._(this.bytes, this.sha256, this.files, this.manifest);

  factory IntegrationPackage.read(Uint8List bytes) {
    final files = StoredDriverZip(bytes).read();
    for (final required in _required) {
      if (!files.containsKey(required)) {
        throw FormatException('Integration package is missing $required.');
      }
    }
    final manifest = IntegrationManifest.fromJson(
      _object(files['manifest.json']!),
    );
    for (final entry in files.entries) {
      _object(entry.value);
    }
    return IntegrationPackage._(
      Uint8List.fromList(bytes),
      digest(bytes),
      Map.unmodifiable(files),
      manifest,
    );
  }

  static const _required = {
    'manifest.json',
    'capabilities.json',
    'mappings.json',
  };

  final Uint8List bytes;
  final String sha256;
  final Map<String, String> files;
  final IntegrationManifest manifest;

  IntegrationIdentity get identity => manifest.identity;

  Map<String, Object?> json(String path) => _object(files[path] ?? '{}');

  static String digest(List<int> bytes) => sha256Of(bytes);

  static Map<String, Object?> _object(String text) {
    final value = jsonDecode(text);
    if (value is! Map<String, Object?>) {
      throw const FormatException('Integration files must be JSON objects.');
    }
    return value;
  }
}

/// Lower-case hexadecimal SHA-256 of [bytes].
String sha256Of(List<int> bytes) => sha256.convert(bytes).toString();
