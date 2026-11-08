import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/digests/sha256.dart';

abstract final class PairingProof {
  static String fingerprint(Uint8List certificate) =>
      base64.encode(SHA256Digest().process(certificate));

  static Uint8List? forCode(String code, Uint8List client, Uint8List server) {
    final value = code.trim();
    if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(value)) {
      return null;
    }
    final nonce = int.parse(value.substring(2), radix: 16);
    final secret = SHA256Digest().process(
      Uint8List.fromList([
        ..._rsaKey(client),
        ..._rsaKey(server),
        nonce >> 8,
        nonce & 255,
      ]),
    );
    return secret.first == int.parse(value.substring(0, 2), radix: 16)
        ? secret
        : null;
  }

  static List<int> _rsaKey(Uint8List certificate) {
    final outer = ASN1Parser(certificate).nextObject() as ASN1Sequence;
    final body = (outer.elements!.first as ASN1Sequence).elements!;
    final index = body.first.tag == 0xa0 ? 6 : 5;
    final subjectKey = body[index] as ASN1Sequence;
    final bits = subjectKey.elements![1] as ASN1BitString;
    final rsa =
        ASN1Parser(Uint8List.fromList(bits.stringValues!)).nextObject()
            as ASN1Sequence;
    return [
      for (final value in rsa.elements!.cast<ASN1Integer>())
        ...value.valueBytes!.skipWhile((byte) => byte == 0),
    ];
  }
}
