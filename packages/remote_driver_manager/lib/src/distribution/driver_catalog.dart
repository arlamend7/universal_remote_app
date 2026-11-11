import 'dart:convert';

import 'driver_release.dart';
import 'driver_signature_verifier.dart';

final class DriverCatalog {
  DriverCatalog._(this.revision, this.publishedAt, this.keyId, this.releases);

  static const maximumBytes = 2 * 1024 * 1024;

  final int revision;
  final DateTime publishedAt;
  final String keyId;
  final List<DriverRelease> releases;

  static Future<DriverCatalog> verify(
    String envelope,
    DriverSignatureVerifier verifySignature,
  ) async {
    if (envelope.length > maximumBytes) {
      throw const FormatException('Driver catalog exceeds the size limit.');
    }
    final signed = jsonDecode(envelope);
    if (signed is! Map<String, Object?> || signed.length != 3) {
      throw const FormatException('Invalid signed driver catalog envelope.');
    }
    final key = signed['keyId'];
    final payload = signed['payload'];
    final signature = signed['signature'];
    if (key is! String ||
        _key.firstMatch(key)?.end != key.length ||
        payload is! String ||
        signature is! String ||
        signature.isEmpty ||
        signature.length > 512) {
      throw const FormatException('Invalid driver catalog signature metadata.');
    }
    final bytes = base64Decode(payload);
    if (!await verifySignature(key, bytes, base64Decode(signature))) {
      throw const FormatException('The driver catalog signature is invalid.');
    }
    return _decode(jsonDecode(utf8.decode(bytes)), key);
  }

  static DriverCatalog _decode(Object? value, String key) {
    if (value is! Map<String, Object?> ||
        value.length != 4 ||
        value['schemaVersion'] is! int ||
        value['schemaVersion'] != 1) {
      throw const FormatException('Unsupported driver catalog schema.');
    }
    final revision = value['revision'];
    final published = value['publishedAt'];
    final releases = value['releases'];
    if (revision is! int ||
        revision < 1 ||
        published is! String ||
        !published.endsWith('Z') ||
        releases is! List<Object?> ||
        releases.length > 1024) {
      throw const FormatException('Invalid driver catalog metadata.');
    }
    final timestamp = DateTime.tryParse(published);
    if (timestamp == null) {
      throw const FormatException('Invalid driver catalog timestamp.');
    }
    final parsed = releases.map(DriverRelease.fromJson).toList();
    if (parsed.map((release) => release.path).toSet().length != parsed.length) {
      throw const FormatException('Duplicate driver release.');
    }
    return DriverCatalog._(revision, timestamp, key, List.unmodifiable(parsed));
  }

  static final _key = RegExp(r'^[a-z][a-z0-9_-]{0,63}$');
}
