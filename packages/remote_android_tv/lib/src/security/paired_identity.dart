import 'dart:convert';

import 'client_identity.dart';

final class PairedIdentity {
  const PairedIdentity(this.client, this.fingerprint);
  final ClientIdentity client;
  final String fingerprint;

  factory PairedIdentity.decode(String credential) {
    final data = jsonDecode(credential) as Map<String, dynamic>;
    return PairedIdentity(
      ClientIdentity(data['certificate'] as String, data['key'] as String),
      data['peer'] as String,
    );
  }

  String encode() => jsonEncode({
    'certificate': client.certificate,
    'key': client.privateKey,
    'peer': fingerprint,
  });
}
