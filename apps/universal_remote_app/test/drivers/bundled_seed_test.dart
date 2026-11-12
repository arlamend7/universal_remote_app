import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';
import 'package:universal_remote_app/data/drivers/asset_driver_seed.dart';
import 'package:universal_remote_app/data/drivers/platform_driver_configuration.dart';

import '../support/counting_credential_store.dart';

/// Public half of the production signing key (`universal-remote-1`).
const _publicKey = '''
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEe/f/60DAeQW6Sd40CQH2UyQIAhHE
RTlWpEtg1CQHFwt8EWeP8UPZqkeunh1zMQwKYa3QfG1W49pnpfeHSAHdfg==
-----END PUBLIC KEY-----
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bundled seed installs offline through full verification', () async {
    final seed = await AssetDriverSeed.load(rootBundle);
    expect(seed, isNotNull);
    final directory = await Directory.systemTemp.createTemp('seed');
    addTearDown(() => directory.delete(recursive: true));
    final key = File('${directory.path}/public.pem')
      ..writeAsStringSync(_publicKey);
    var sequence = 0;
    Future<bool> verify(
      String keyId,
      Uint8List payload,
      Uint8List signature,
    ) async {
      if (keyId != 'universal-remote-1') {
        return false;
      }
      final input = File('${directory.path}/payload-${sequence++}')
        ..writeAsBytesSync(payload);
      final proof = File('${input.path}.sig')..writeAsBytesSync(signature);
      final result = await Process.run('openssl', [
        'dgst',
        '-sha256',
        '-verify',
        key.path,
        '-signature',
        proof.path,
        input.path,
      ]);
      return result.exitCode == 0;
    }

    final service = IntegrationService(
      root: Directory('${directory.path}/installed-drivers'),
      engines: PlatformDriverConfiguration.engines(),
      credentials: CountingCredentialStore(),
      verify: verify,
    );
    final registry = ProviderRegistry();
    await service.initialize(registry, seed: seed);
    expect(registry.definitions.map((definition) => definition.id).toSet(), {
      'lg.webos',
      'android.tv',
      'samsung.tizen',
    });
    final inventory = await service.installer.inventory();
    expect(inventory.keys.toSet(), {
      'lg.webos.22-plus',
      'lg.webos.legacy',
      'android.tv.remote-v2',
      'samsung.tizen.supported',
    });
    final generation = await service.installer.load('lg.webos.22-plus');
    expect(generation!.record.source, 'seed');
    expect(seed!.objects.containsKey(generation.sha256), isTrue);
  });
}
