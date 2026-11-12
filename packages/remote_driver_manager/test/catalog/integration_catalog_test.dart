import 'dart:convert';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';
import 'package:test/test.dart';

import '../fixture_driver_signer.dart';

Map<String, Object?> _fixture() {
  var directory = Directory.current.absolute;
  while (!File('${directory.path}/drivers/fixtures/v2/catalog-payload.json')
      .existsSync()) {
    directory = directory.parent;
  }
  final file = File(
    '${directory.path}/drivers/fixtures/v2/catalog-payload.json',
  );
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

void main() {
  test('decodes stable integrations with hash-addressed package objects', () {
    final catalog = IntegrationCatalog.decode(_fixture(), 'fixture-key');
    final integration = catalog.integration('example.json-websocket')!;
    expect(catalog.revision, 42);
    expect(integration.providerId, 'example.smarttv');
    expect(integration.lastUpdatedAt, DateTime.utc(2026, 11, 11, 21, 25));
    expect(
      integration.package,
      'packages/objects/${integration.sha256}/driver.zip',
    );
    expect(integration.development, isTrue);
    expect(integration.conditionalCapabilities, {RemoteCapability.mute});
    expect(integration.compatibility.osVersion?.expression, '>=7');
    expect(integration.profiles.map((profile) => profile.id), [
      'bootstrap',
      'example-os-9',
    ]);
    expect(integration.replaces, {'example-tv'});
  });

  test('rejects mutable or versioned package paths', () {
    final payload = _fixture();
    final entry = {
      ...((payload['integrations']! as List).single as Map<String, Object?>),
    };
    for (final path in [
      'packages/example/1.0.0/driver.zip',
      'packages/objects/${'a' * 64}/driver.zip',
    ]) {
      entry['package'] = path;
      expect(
        () => IntegrationCatalog.decode({
          ...payload,
          'integrations': [entry],
        }, 'fixture-key'),
        throwsFormatException,
      );
    }
  });

  test('rejects duplicate integration IDs and legacy schemas', () {
    final payload = _fixture();
    final entry = (payload['integrations']! as List).single;
    expect(
      () => IntegrationCatalog.decode({
        ...payload,
        'integrations': [entry, entry],
      }, 'fixture-key'),
      throwsFormatException,
    );
    expect(
      () => IntegrationCatalog.decode({
        ...payload,
        'schemaVersion': 1,
      }, 'fixture-key'),
      throwsFormatException,
    );
  });

  test('only a correctly signed envelope is decoded', () async {
    final directory = await Directory.systemTemp.createTemp('catalog-v2');
    addTearDown(() => directory.delete(recursive: true));
    final signer = FixtureDriverSigner(directory);
    await signer.initialize();
    final payload = utf8.encode(jsonEncode(_fixture()));
    final envelope = jsonEncode({
      'keyId': 'fixture-key',
      'payload': base64Encode(payload),
      'signature': base64Encode(await signer.sign(payload)),
    });
    final catalog = await IntegrationCatalog.verify(envelope, signer.verify);
    expect(catalog.integrations.single.id, 'example.json-websocket');
    final tampered = jsonEncode({
      'keyId': 'fixture-key',
      'payload': base64Encode(
        utf8.encode(jsonEncode({..._fixture()}..['revision'] = 43)),
      ),
      'signature': base64Encode(await signer.sign(payload)),
    });
    await expectLater(
      IntegrationCatalog.verify(tampered, signer.verify),
      throwsFormatException,
    );
  });
}
