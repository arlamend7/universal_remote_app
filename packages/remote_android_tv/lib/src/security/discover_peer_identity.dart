import 'dart:io';

import 'pairing_proof.dart';

/// Reads the certificate advertised by the pairing endpoint without trusting it
/// or sending any pairing messages. A saved pin is still required to reconnect.
Future<String?> discoverPeerIdentity(String address) async {
  String? identity;
  try {
    final socket = await SecureSocket.connect(
      address,
      6467,
      context: SecurityContext(withTrustedRoots: false),
      timeout: const Duration(milliseconds: 900),
      onBadCertificate: (certificate) {
        identity = PairingProof.fingerprint(certificate.der);
        return false;
      },
    );
    socket.destroy();
  } on IOException {
    return identity;
  }
  return identity;
}
