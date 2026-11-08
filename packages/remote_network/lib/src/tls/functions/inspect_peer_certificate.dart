import 'dart:io';

import '../models/peer_certificate.dart';

/// Reads certificate evidence while rejecting the unauthenticated handshake.
/// Sends no application data and never installs trust or a global override.
Future<PeerCertificate> inspectPeerCertificate(
  Uri endpoint, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  if (endpoint.scheme != 'wss' ||
      endpoint.host.isEmpty ||
      endpoint.userInfo.isNotEmpty ||
      endpoint.hasFragment) {
    throw ArgumentError('Expected a secure TV endpoint without credentials.');
  }
  PeerCertificate? observed;
  try {
    final socket = await SecureSocket.connect(
      endpoint.host,
      endpoint.hasPort ? endpoint.port : 443,
      context: SecurityContext(withTrustedRoots: false),
      timeout: timeout,
      onBadCertificate: (certificate) {
        observed = PeerCertificate.fromX509(certificate);
        return false;
      },
    );
    socket.destroy();
  } on HandshakeException {
    if (observed == null) {
      rethrow;
    }
  }
  final certificate = observed;
  if (certificate == null) {
    throw const HandshakeException('The TV did not provide a certificate.');
  }
  return certificate;
}
