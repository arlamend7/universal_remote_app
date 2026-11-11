import 'dart:io';

import 'pairing_proof.dart';

/// Reads the certificate advertised by the pairing endpoint without trusting it
/// or sending any pairing messages. A saved pin is still required to reconnect.
Future<String?> discoverPeerIdentity(
  String address, {
  int port = 6467,
  Duration timeout = const Duration(milliseconds: 900),
  bool reportNetworkFailure = false,
}) async {
  String? identity;
  try {
    final socket = await SecureSocket.connect(
      address,
      port,
      context: SecurityContext(withTrustedRoots: false),
      timeout: timeout,
      onBadCertificate: (certificate) {
        identity = PairingProof.fingerprint(certificate.der);
        return false;
      },
    );
    socket.destroy();
  } on IOException {
    if (identity == null && reportNetworkFailure) {
      rethrow;
    }
    return identity;
  }
  return identity;
}
