import 'dart:convert';
import 'dart:io';

/// Certificate evidence only; collecting it does not authorize a connection.
final class PeerCertificate {
  PeerCertificate.fromX509(X509Certificate certificate)
    : derBase64 = base64Encode(certificate.der),
      fingerprint = certificate.sha1
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join(':')
          .toUpperCase(),
      subject = certificate.subject;

  const PeerCertificate({
    required this.derBase64,
    required this.fingerprint,
    required this.subject,
  });

  final String derBase64;

  /// SHA-1 is displayed for comparison; trust uses the complete DER bytes.
  final String fingerprint;
  final String subject;
}
