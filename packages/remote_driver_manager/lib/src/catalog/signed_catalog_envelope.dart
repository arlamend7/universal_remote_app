import 'dart:convert';
import 'dart:typed_data';

import '../distribution/driver_signature_verifier.dart';

/// The `{keyId, payload, signature}` envelope shared by every catalog schema.
final class SignedCatalogEnvelope {
  SignedCatalogEnvelope._(this.keyId, this.payload);

  static const maximumBytes = 2 * 1024 * 1024;
  static final _key = RegExp(r'^[a-z][a-z0-9_-]{0,63}$');

  final String keyId;

  /// The signed payload bytes; decode only after [open] verified them.
  final Uint8List payload;

  /// Verifies the signature before any payload field is interpreted.
  static Future<SignedCatalogEnvelope> open(
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
    return SignedCatalogEnvelope._(key, bytes);
  }

  Object? decodePayload() => jsonDecode(utf8.decode(payload));
}
