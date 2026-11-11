import 'dart:io';
import 'dart:typed_data';

final class FixtureDriverSigner {
  FixtureDriverSigner(this.directory);

  final Directory directory;
  int _sequence = 0;
  String get _key => '${directory.path}/fixture.pem';
  String get _publicKey => '${directory.path}/fixture-public.pem';

  Future<void> initialize() async {
    await _openssl([
      'genpkey',
      '-algorithm',
      'EC',
      '-pkeyopt',
      'ec_paramgen_curve:P-256',
      '-out',
      _key,
    ]);
    await _openssl(['pkey', '-in', _key, '-pubout', '-out', _publicKey]);
  }

  Future<Uint8List> sign(List<int> bytes) async {
    final input = File('${directory.path}/input-${_sequence++}');
    final signature = File('${input.path}.sig');
    await input.writeAsBytes(bytes);
    await _openssl([
      'dgst',
      '-sha256',
      '-sign',
      _key,
      '-out',
      signature.path,
      input.path,
    ]);
    return signature.readAsBytes();
  }

  Future<bool> verify(
    String keyId,
    Uint8List payload,
    Uint8List signature,
  ) async {
    if (keyId != 'fixture-key') {
      return false;
    }
    final input = File('${directory.path}/verify-${_sequence++}');
    final proof = File('${input.path}.sig');
    await input.writeAsBytes(payload);
    await proof.writeAsBytes(signature);
    final result = await Process.run('openssl', [
      'dgst',
      '-sha256',
      '-verify',
      _publicKey,
      '-signature',
      proof.path,
      input.path,
    ]);
    return result.exitCode == 0;
  }

  static Future<void> _openssl(List<String> args) async {
    final result = await Process.run('openssl', args);
    if (result.exitCode != 0) {
      throw StateError('The fixture signature command failed.');
    }
  }
}
