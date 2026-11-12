import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/integrations.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';
import 'package:test/test.dart';

import '../adapters/lg_webos/support/fake_transport.dart';
import '../adapters/lg_webos/support/memory_credentials.dart';
import '../adapters/lg_webos/support/standard_responses.dart';
import '../integrations/ssap_test_integration.dart';
import 'static_integration_planner.dart';

void main() {
  late List<FakeTransport> sockets;
  late ProtocolEngineRegistry registry;
  late MemoryCredentials credentials;
  final rejected = <String>{};

  FakeTransport socket() {
    final transport = FakeTransport();
    standardResponses(transport);
    final standard = transport.respond!;
    transport.respond = (request) {
      if (rejected.contains(request['uri'])) {
        transport.reject(request, '403 permission denied');
        return;
      }
      standard(request);
    };
    sockets.add(transport);
    return transport;
  }

  setUp(() {
    sockets = [];
    rejected.clear();
    credentials = MemoryCredentials();
    registry = ProtocolEngineRegistry([
      SsapEngine(connector: (_) async => socket()),
    ]);
  });

  IntegrationDefinition definition({
    Map<String, Object?>? mappings,
    Map<String, Object?>? capabilities,
    Map<String, Object?>? manifest,
  }) => IntegrationDefinition.compile({
    ...ssapFiles(
      mappings: mappings,
      capabilities: capabilities,
      manifest: manifest,
    ),
  }, registry);

  RemoteDevice device({Map<String, String> metadata = const {}}) =>
      RemoteDevice(
        id: 'lg.webos:uuid:generic',
        name: 'TV',
        providerId: 'test.ssap',
        endpoints: [Uri.parse('ws://192.168.1.20:3000')],
        metadata: {'allowInsecure': 'true', ...metadata},
      );

  GenericTvController controller(
    StaticIntegrationPlanner planner, {
    RemoteDevice? target,
    WakeSender? wake,
  }) {
    final remote = GenericTvController(
      target ?? device(),
      planner: planner,
      credentials: credentials,
      wakeSender: wake,
    );
    addTearDown(remote.dispose);
    return remote;
  }

  IntegrationPlan plan(IntegrationDefinition definition, [String? profile]) =>
      IntegrationPlan(
        definition,
        definition.profile(profile ?? 'bootstrap'),
        metadata: const {'driverIntegrationId': 'test.ssap'},
      );

  test('connects, verifies capabilities and sends mapped operations', () async {
    final planner = StaticIntegrationPlanner(plan(definition()));
    final remote = controller(planner);
    final states = <DeviceConnectionState>[];
    remote.connectionStates.listen(states.add);
    await remote.connect();
    expect(states, [
      DeviceConnectionState.connecting,
      DeviceConnectionState.pairing,
      DeviceConnectionState.connected,
    ]);
    expect(credentials.values['lg.webos:uuid:generic'], 'secret');
    expect(planner.calls, [
      'prepare',
      'refine:null',
      'remember:test.ssap:bootstrap',
    ]);
    expect(
      {for (final item in remote.evidence) item.capability: item.availability},
      {
        RemoteCapability.volume: CapabilityAvailability.known,
        RemoteCapability.mute: CapabilityAvailability.known,
        RemoteCapability.inputs: CapabilityAvailability.known,
      },
    );
    expect(remote.device.metadata['driverIntegrationId'], 'test.ssap');
    await remote.volumeUp();
    expect(sockets.single.sent.last['uri'], 'ssap://audio/volumeUp');
    await remote.toggleMute();
    expect(
      sockets.single.sent
          .map((sent) => sent['uri'])
          .toList()
          .sublist(sockets.single.sent.length - 2),
      ['ssap://audio/getVolume', 'ssap://audio/setMute'],
    );
    expect(sockets.single.sent.last['payload'], {'mute': true});
    await remote.selectInput('HDMI_2');
    expect(sockets.single.sent.last['payload'], {'inputId': 'HDMI_2'});
    expect((await remote.inputs()).single.name, 'Console');
  });

  test(
    'unmapped operations are unsupported; ungated reads stay empty',
    () async {
      final remote = controller(StaticIntegrationPlanner(plan(definition())));
      await remote.connect();
      await expectLater(
        remote.sendMedia(MediaAction.play),
        throwsA(
          isA<RemoteException>().having((e) => e.code, 'code', 'unsupported'),
        ),
      );
      expect(await remote.applications(), isEmpty);
      expect(await remote.playbackState(), isNull);
      expect(remote.canWake, isFalse);
    },
  );

  test('declared constraints reject arguments before sending', () async {
    final mappings = {
      ...ssapMappings(),
      'set-volume': {
        'kind': 'ssap.request',
        'uri': 'ssap://audio/setVolume',
        'payload': {
          'volume': {r'$argument': 'volume'},
        },
        'constraints': {
          'volume': {'minimum': 0, 'maximum': 100},
        },
      },
    };
    final remote = controller(
      StaticIntegrationPlanner(plan(definition(mappings: mappings))),
    );
    await remote.connect();
    final sent = sockets.single.sent.length;
    expect(() => remote.setVolume(101), throwsArgumentError);
    expect(sockets.single.sent.length, sent);
    await remote.setVolume(40);
    expect(sockets.single.sent.last['payload'], {'volume': 40});
  });

  test('declared failure codes withdraw the capability', () async {
    rejected.add('ssap://audio/setMute');
    final remote = controller(StaticIntegrationPlanner(plan(definition())));
    await remote.connect();
    final changed = remote.capabilityChanges.first;
    await expectLater(remote.setMuted(true), throwsA(isA<RemoteException>()));
    await changed;
    expect(remote.supports(RemoteCapability.mute), isFalse);
    await expectLater(
      remote.setMuted(false),
      throwsA(
        isA<RemoteException>().having((e) => e.code, 'code', 'unavailable'),
      ),
    );
  });

  test('identified software hands off once without re-pairing', () async {
    final modern = definition(
      manifest: {...ssapManifest(), 'integrationId': 'test.ssap.modern'},
    );
    final planner = StaticIntegrationPlanner(
      plan(definition()),
      refined: plan(modern, 'modern'),
    );
    final remote = controller(planner);
    await remote.connect();
    expect(sockets.length, 2);
    expect(sockets.first.closed, isTrue);
    expect(remote.plan?.identity.integrationId, 'test.ssap.modern');
    expect(planner.calls.last, 'remember:test.ssap.modern:modern');
    expect(
      sockets.last.sent.first['payload'],
      containsPair('client-key', 'secret'),
    );
    await remote.volumeUp();
    expect(sockets.last.sent.last['uri'], 'ssap://audio/volumeUpModern');
  });

  test('reconnects after an unexpected loss when the policy allows', () async {
    final files = ssapFiles();
    files['connection.json'] =
        '{"registration": {"manifestVersion": 1, "permissions": []}, '
        '"allowLegacyTransport": true, "session": {"reconnectAttempts": 1}}';
    final remote = controller(
      StaticIntegrationPlanner(
        plan(IntegrationDefinition.compile(files, registry)),
      ),
    );
    await remote.connect();
    final states = <DeviceConnectionState>[];
    remote.connectionStates.listen(states.add);
    await sockets.single.close();
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    expect(
      states,
      containsAllInOrder([
        DeviceConnectionState.disconnected,
        DeviceConnectionState.reconnecting,
        DeviceConnectionState.connected,
      ]),
    );
    expect(sockets.length, 2);
  });

  test('network wake uses the learned MAC address', () async {
    final mappings = {
      ...ssapMappings(),
      'wake': {'kind': 'network.wake-on-lan'},
    };
    final manifest = ssapManifest();
    final runtime = {...manifest['requiredRuntime']! as Map<String, Object?>};
    runtime['operations'] = [
      ...(runtime['operations']! as List),
      'network.wake-on-lan',
    ];
    final woken = <String>[];
    final remote = controller(
      StaticIntegrationPlanner(
        plan(
          definition(
            mappings: mappings,
            manifest: {...manifest, 'requiredRuntime': runtime},
          ),
        ),
      ),
      target: device(metadata: {'macAddress': 'AA:BB:CC:DD:EE:FF'}),
      wake: (mac, broadcast) async => woken.add('$mac@$broadcast'),
    );
    await remote.connect();
    expect(remote.canWake, isTrue);
    await remote.wake();
    expect(woken, ['aa:bb:cc:dd:ee:ff@255.255.255.255']);
  });
}
