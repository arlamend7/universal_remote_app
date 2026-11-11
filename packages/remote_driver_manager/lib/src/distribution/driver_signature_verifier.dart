import 'dart:typed_data';

/// Trust is configured by the host. An unknown key ID must be rejected.
typedef DriverSignatureVerifier = Future<bool> Function(
  String keyId,
  Uint8List payload,
  Uint8List signature,
);
