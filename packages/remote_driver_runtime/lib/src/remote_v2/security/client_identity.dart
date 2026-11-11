import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';

final class ClientIdentity {
  const ClientIdentity(this.certificate, this.privateKey);

  final String certificate;
  final String privateKey;

  static Future<ClientIdentity> generate() => Isolate.run(_generate);

  static ClientIdentity _generate() {
    final source = Random.secure();
    final random = FortunaRandom()
      ..seed(
        KeyParameter(
          Uint8List.fromList(List.generate(32, (_) => source.nextInt(256))),
        ),
      );
    final generator = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64),
          random,
        ),
      );
    final pair = generator.generateKeyPair();
    final public = pair.publicKey;
    final private = pair.privateKey;
    final serial =
        BigInt.parse(
          List.generate(
            16,
            (_) => source.nextInt(256).toRadixString(16).padLeft(2, '0'),
          ).join(),
          radix: 16,
        ) +
        BigInt.one;
    return ClientIdentity(
      _pem('CERTIFICATE', _certificate(public, private, serial)),
      _pem('RSA PRIVATE KEY', _privateKey(public, private)),
    );
  }

  static Uint8List _certificate(
    RSAPublicKey public,
    RSAPrivateKey private,
    BigInt serial,
  ) {
    final signatureAlgorithm = _algorithm('1.2.840.113549.1.1.11');
    final subject = _sequence([
      ASN1Set(
        elements: [
          _sequence([
            ASN1ObjectIdentifier.fromIdentifierString('2.5.4.3'),
            ASN1UTF8String(
              utf8StringValue: 'Universal Remote ${serial.toRadixString(16)}',
            ),
          ]),
        ],
      ),
    ]);
    final now = DateTime.now().toUtc();
    final publicKey = _sequence([
      ASN1Integer(public.modulus!),
      ASN1Integer(public.publicExponent!),
    ]);
    final body = _sequence([
      ASN1Integer(serial),
      signatureAlgorithm,
      subject,
      _sequence([
        ASN1UtcTime(now.subtract(const Duration(days: 1))),
        ASN1UtcTime(now.add(const Duration(days: 3650))),
      ]),
      subject,
      _sequence([
        _algorithm('1.2.840.113549.1.1.1'),
        ASN1BitString(stringValues: publicKey.encode()),
      ]),
    ]);
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201')
      ..init(true, PrivateKeyParameter<RSAPrivateKey>(private));
    final signature = signer.generateSignature(body.encode());
    return _sequence([
      body,
      signatureAlgorithm,
      ASN1BitString(stringValues: signature.bytes),
    ]).encode();
  }

  static Uint8List _privateKey(RSAPublicKey public, RSAPrivateKey private) {
    final p = private.p!;
    final q = private.q!;
    final d = private.privateExponent!;
    return _sequence([
      for (final integer in [
        BigInt.zero,
        public.modulus!,
        public.publicExponent!,
        d,
        p,
        q,
        d % (p - BigInt.one),
        d % (q - BigInt.one),
        q.modInverse(p),
      ])
        ASN1Integer(integer),
    ]).encode();
  }

  static ASN1Sequence _sequence(List<ASN1Object> elements) =>
      ASN1Sequence(elements: elements);

  static ASN1Sequence _algorithm(String oid) =>
      _sequence([ASN1ObjectIdentifier.fromIdentifierString(oid), ASN1Null()]);

  static String _pem(String label, List<int> der) =>
      '-----BEGIN $label-----\n${base64.encode(der)}\n-----END $label-----\n';

  Uint8List get certificateDer => base64.decode(certificate.split('\n')[1]);

  SecurityContext context() => SecurityContext(withTrustedRoots: false)
    ..minimumTlsProtocolVersion = TlsProtocolVersion.tls1_2
    ..useCertificateChainBytes(utf8.encode(certificate))
    ..usePrivateKeyBytes(utf8.encode(privateKey));
}
