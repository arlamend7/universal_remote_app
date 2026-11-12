import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/integrations.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';
import 'package:test/test.dart';

import '../adapters/lg_webos/support/fake_transport.dart';
import '../adapters/lg_webos/support/standard_responses.dart';
import '../engines/engine_test_context.dart';
import 'ssap_test_integration.dart';

void main() {
  late FakeTransport socket;
  late ProtocolEngineRegistry registry;

  setUp(() {
    socket = FakeTransport();
    standardResponses(socket);
    registry = ProtocolEngineRegistry([
      SsapEngine(connector: (_) async => socket),
      RemoteV2Engine(),
    ]);
  });

  Future<String> sendVolumeUp(
    IntegrationDefinition definition,
    String profileId,
  ) async {
    final context = EngineTestContext(
      RemoteDevice(
        id: 'lg.webos:uuid:definition',
        name: 'TV',
        providerId: 'lg.webos',
        endpoints: [Uri.parse('ws://192.168.1.20:3000')],
        metadata: const {'allowInsecure': 'true'},
      ),
      connection: definition.connection,
    );
    final session = await definition.engine.open(
      context.build(definition.engine),
    );
    addTearDown(session.close);
    final table = definition.operations(definition.profile(profileId));
    await session.execute(table['volume-up']!.operation, const {});
    return socket.sent.last['uri'] as String;
  }

  test('a valid JSON change alters the transmitted operation', () async {
    final original = IntegrationDefinition.compile(ssapFiles(), registry);
    expect(await sendVolumeUp(original, 'bootstrap'), 'ssap://audio/volumeUp');
    socket = FakeTransport();
    standardResponses(socket);
    final edited = IntegrationDefinition.compile(
      ssapFiles(mappings: ssapMappings(volumeUp: 'ssap://audio/setVolume')),
      registry,
    );
    expect(await sendVolumeUp(edited, 'bootstrap'), 'ssap://audio/setVolume');
  });

  test(
    'a profile override takes effect and is visible in diagnostics',
    () async {
      final definition = IntegrationDefinition.compile(ssapFiles(), registry);
      expect(
        await sendVolumeUp(definition, 'modern'),
        'ssap://audio/volumeUpModern',
      );
      final diagnostics = definition
          .operations(definition.profile('modern'))
          .diagnostics;
      expect(diagnostics['volume-up'], {
        'kind': 'ssap.request',
        'uri': 'ssap://audio/volumeUpModern',
        'payload': <String, Object?>{},
        'result': 'none',
        'muteUri': null,
        'timeoutMs': null,
        'profile': 'modern',
      });
      expect(diagnostics['read-volume']?['readOnly'], isTrue);
    },
  );

  test('invalid or misleading packages are rejected', () {
    final invalid = <String, Map<String, String>>{
      'unsafe URI': ssapFiles(
        mappings: ssapMappings(volumeUp: 'ssap://evil.service/x'),
      ),
      'undeclared kind': ssapFiles(
        mappings: {
          ...ssapMappings(),
          'key-menu': {'kind': 'ssap.pointer-click'},
        },
      ),
      'other engine kind': ssapFiles(
        manifest: {
          ...ssapManifest(),
          'requiredRuntime': {
            'api': 2,
            'operations': [
              'ssap.request',
              'ssap.pointer-button',
              'remote-v2.key',
            ],
          },
        },
        mappings: {
          ...ssapMappings(),
          'key-menu': {'kind': 'remote-v2.key', 'code': 82},
        },
      ),
      'capability without executable set': ssapFiles(
        manifest: ssapManifest(
          capabilities: ['volume', 'mute', 'inputs', 'power'],
        ),
        capabilities: {
          ...ssapCapabilities(),
          'power': {
            'alternatives': [
              ['power-off'],
            ],
          },
        },
      ),
      'manifest capability summary mismatch': ssapFiles(
        manifest: ssapManifest(capabilities: ['volume']),
      ),
      'unknown runtime operation': ssapFiles(
        mappings: {
          ...ssapMappings(),
          'format-disk': {'kind': 'ssap.request', 'uri': 'ssap://system/x'},
        },
      ),
    };
    for (final entry in invalid.entries) {
      expect(
        () => IntegrationDefinition.compile(entry.value, registry),
        throwsFormatException,
        reason: entry.key,
      );
    }
    expect(
      () => IntegrationDefinition.compile(
        ssapFiles(),
        ProtocolEngineRegistry([RemoteV2Engine()]),
      ),
      throwsFormatException,
    );
  });

  group('capability resolution', () {
    late IntegrationDefinition definition;
    setUp(() {
      definition = IntegrationDefinition.compile(ssapFiles(), registry);
    });

    Map<RemoteCapability, ResolvedCapability> resolve({
      String profile = 'bootstrap',
      Map<String, VerificationOutcome> probes = const {},
      Set<String> unusableKinds = const {},
      Map<RemoteCapability, String> withdrawn = const {},
      CompatibilityProfile? custom,
    }) {
      final selected = custom ?? definition.profile(profile);
      return CapabilityResolver.resolve(
        CapabilityInputs(
          definition: definition,
          profile: selected,
          table: definition.operations(selected),
          probes: probes,
          unusableKinds: unusableKinds,
          withdrawn: withdrawn,
        ),
      );
    }

    test('alternative operation sets keep a capability available', () {
      final resolved = resolve(
        probes: {
          'list-inputs': const VerificationOutcome.success([
            DeviceInput('HDMI_1', 'Console'),
          ]),
        },
      );
      expect(resolved[RemoteCapability.mute]!.operations, [
        'set-mute',
        'read-volume',
      ]);
      expect(
        resolved[RemoteCapability.inputs]!.evidence.availability,
        CapabilityAvailability.known,
      );
      final withoutReading = IntegrationDefinition.compile(
        ssapFiles(
          mappings: {...ssapMappings()}..remove('read-volume'),
          capabilities: {
            ...ssapCapabilities(),
            'mute': {
              'alternatives': [
                ['set-mute', 'read-volume'],
                ['key-mute'],
              ],
            },
          },
        ),
        registry,
      );
      final bootstrap = withoutReading.manifest.bootstrapProfile;
      final alternative = CapabilityResolver.resolve(
        CapabilityInputs(
          definition: withoutReading,
          profile: bootstrap,
          table: withoutReading.operations(bootstrap),
        ),
      );
      expect(alternative[RemoteCapability.mute]!.operations, ['key-mute']);
    });

    test('verification failures and unusable channels are reported', () {
      final resolved = resolve(
        probes: {'list-inputs': const VerificationOutcome.success([])},
        unusableKinds: {'ssap.pointer-button'},
      );
      expect(
        resolved[RemoteCapability.inputs]!.evidence.availability,
        CapabilityAvailability.unavailable,
      );
      expect(resolved[RemoteCapability.mute]!.usable, isTrue);
      final failed = resolve(
        probes: {'list-inputs': const VerificationOutcome.failure('denied')},
        withdrawn: {RemoteCapability.volume: 'rejected'},
      );
      expect(failed[RemoteCapability.inputs]!.evidence.reason, 'denied');
      expect(
        failed[RemoteCapability.volume]!.evidence.availability,
        CapabilityAvailability.unavailable,
      );
    });

    test('profiles and restrictions keep capabilities conditional', () {
      final profile = CompatibilityProfile(
        id: 'restricted',
        stage: ProfileStage.identified,
        compatibility: IntegrationCompatibility(),
        disabledCapabilities: {RemoteCapability.volume},
      );
      final resolved = resolve(custom: profile);
      final volume = resolved[RemoteCapability.volume]!.evidence;
      expect(volume.availability, CapabilityAvailability.conditional);
      expect(volume.source, CapabilitySource.profile);
      expect(
        resolved[RemoteCapability.inputs]!.evidence.availability,
        CapabilityAvailability.conditional,
      );
    });
  });
}
