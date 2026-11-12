import 'dart:io';
import 'dart:typed_data';

/// Verifies P-256 signatures with a PEM public key through OpenSSL.
final class OpensslVerifier {
  OpensslVerifier(this.publicKey, this.scratch);

  final File publicKey;
  final Directory scratch;
  int _sequence = 0;

  Future<bool> call(
    String keyId,
    Uint8List payload,
    Uint8List signature,
  ) async {
    if (keyId != 'ci-fixture') {
      return false;
    }
    final input = File('${scratch.path}/payload-${_sequence++}');
    final proof = File('${input.path}.sig');
    await input.writeAsBytes(payload);
    await proof.writeAsBytes(signature);
    final result = await Process.run('openssl', [
      'dgst',
      '-sha256',
      '-verify',
      publicKey.path,
      '-signature',
      proof.path,
      input.path,
    ]);
    return result.exitCode == 0;
  }
}
