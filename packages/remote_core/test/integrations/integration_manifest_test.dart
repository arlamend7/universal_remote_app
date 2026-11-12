import 'package:remote_core/remote_core.dart';
import 'package:test/test.dart';

import 'driver_fixture_file.dart';

void main() {
  test('decodes the shared manifest fixture without a package version', () {
    final manifest = IntegrationManifest.fromJson(
      driverFixture('manifest.json'),
    );
    expect(manifest.identity.integrationId, 'example.json-websocket');
    expect(manifest.identity.providerId, 'example.smarttv');
    expect(manifest.engine, 'json-websocket');
    expect(manifest.lastUpdatedAt, DateTime.utc(2026, 11, 11, 21, 25));
    expect(manifest.credentialScope, CredentialScope.device);
    expect(manifest.bootstrapProfile.id, 'bootstrap');
    expect(manifest.profiles.last.disabledCapabilities, {
      RemoteCapability.mute,
    });
    expect(manifest.replaces, {'example-tv'});
    expect(
      IntegrationManifest.fromJson(manifest.toJson()).toJson(),
      manifest.toJson(),
    );
  });

  test('rejects release numbers and missing bootstrap profiles', () {
    final versioned = {...driverFixture('manifest.json'), 'version': '1.0.0'};
    expect(
      () => IntegrationManifest.fromJson(versioned),
      throwsFormatException,
    );
    final identifiedOnly = {
      ...driverFixture('manifest.json'),
      'profiles': [
        {'id': 'only', 'stage': 'identified'},
      ],
    };
    expect(
      () => IntegrationManifest.fromJson(identifiedOnly),
      throwsFormatException,
    );
  });

  test('a bootstrap profile cannot claim software it has not identified', () {
    expect(
      () => CompatibilityProfile.fromJson({
        'id': 'early',
        'stage': 'bootstrap',
        'compatibility': {'osVersion': '>=7'},
      }),
      throwsFormatException,
    );
  });

  test('capability declarations select the first complete operation set', () {
    final capabilities = driverFixture('capabilities.json');
    final mute = CapabilityDeclaration.fromJson('mute', capabilities['mute']);
    expect(mute.select({'set-mute', 'read-volume'}.contains), [
      'set-mute',
      'read-volume',
    ]);
    expect(mute.select({'toggle-mute', 'set-mute'}.contains), ['toggle-mute']);
    expect(mute.select({'set-mute'}.contains), isNull);
    expect(mute.disableOn, {'unsupported', 'permission'});
    final condition = mute.conditions.single;
    expect(condition.evaluate({'feature.audio': 'false'}), isFalse);
    expect(condition.evaluate({'device.is-tv': 'true'}), isTrue);
    expect(condition.evaluate(const {}), isNull);
  });

  test('operation mappings only accept the runtime vocabulary', () {
    final mappings = driverFixture('mappings.json');
    for (final entry in mappings.entries) {
      final mapping = OperationMapping.fromJson(entry.key, entry.value);
      expect(mapping.engine, 'json-websocket');
    }
    expect(
      () => OperationMapping.fromJson('format-disk', {
        'kind': 'json-websocket.request',
      }),
      throwsFormatException,
    );
    expect(
      RuntimeOperations.media(MediaAction.fastForward),
      'media-fast-forward',
    );
    expect(RuntimeOperations.key(RemoteKey.liveTv), 'key-live-tv');
    expect(RuntimeOperations.key(RemoteKey.digit0), 'key-digit0');
    expect(RuntimeOperations.isMappable('subscribe-volume'), isTrue);
    expect(RuntimeOperations.isMappable('subscribe-everything'), isFalse);
  });

  test('the JSON schema capability list matches the Dart contract', () {
    final common = driverSchema('common.schema.json');
    final definitions = common[r'$defs']! as Map<String, Object?>;
    final capability = definitions['capability']! as Map<String, Object?>;
    expect(
      (capability['enum']! as List).toSet(),
      RemoteCapability.values.map((value) => value.name).toSet(),
    );
  });
}
