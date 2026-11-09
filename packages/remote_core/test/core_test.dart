import 'package:remote_core/remote_core.dart';
import 'package:test/test.dart';

import 'support/test_controller.dart';
import 'support/test_device.dart';
import 'support/observation_identifier.dart';

void main() {
  test(
    'a paired Android TV keeps its profile across an address change',
    () async {
      RemoteDevice device(String id, String ip, Map<String, String> metadata) =>
          RemoteDevice(
            id: id,
            name: 'TV',
            providerId: 'android.tv',
            stableIdentity: false,
            endpoints: [Uri(scheme: 'tls', host: ip, port: 6466)],
            metadata: metadata,
          );
      var saved = device('saved', '192.168.1.10', {
        'verifiedPeerIdentity': 'pin',
      });
      final found = device('discovered', '192.168.1.11', {
        'advertisedPeerIdentity': 'pin',
      });
      final other = device('other', '192.168.1.10', {
        'advertisedPeerIdentity': 'other',
      });
      expect(const DeviceIdentifierResolver().same(saved, other), isFalse);
      final profiles = DiscoveryProfiles(
        profiles: () => [saved],
        update: (_, change) async => saved = change(saved) ?? saved,
      );
      await profiles.updateAddress(found);
      expect(saved.id, 'saved');
      expect(saved.endpoints.single.host, '192.168.1.11');
      expect(saved.metadata['verifiedPeerIdentity'], 'pin');
    },
  );

  test(
    'wake workflow wakes once and retries only failures the provider allows',
    () async {
      final events = <String>[];
      const workflow = DeviceConnectionWorkflow(retryDelay: Duration.zero);
      await workflow.run(
        wake: () async {
          events.add('wake');
        },
        connect: () async {
          events.add('connect');
          if (events.length == 2) {
            throw const RemoteException('starting', 'Device is starting.');
          }
        },
        isCurrent: () => true,
        canRetry: (error) =>
            error is RemoteException && error.code == 'starting',
        reset: () async {
          events.add('reset');
        },
      );
      expect(events, ['wake', 'connect', 'reset', 'connect']);
    },
  );

  test('models copy capability metadata and typed resolution is optional', () {
    final caps = {RemoteCapability.volume};
    final tv = RemoteDevice(id: 'id', name: 'TV', capabilities: caps);
    caps.clear();
    expect(tv.capabilities, {RemoteCapability.volume});
    expect(() => tv.capabilities.clear(), throwsUnsupportedError);
    final client = TestController(tv);
    expect(client.supports(RemoteCapability.volume), isTrue);
    expect(client.supports(RemoteCapability.navigation), isFalse);
    expect(() => RemoteDevice(id: '', name: 'TV'), throwsArgumentError);
  });
  test('registry rejects duplicate IDs and selects the exact definition', () {
    final definition = ProviderDefinition(
      identifier: ObservationIdentifier('one', DiscoveryProtocol.ssdp, 'test'),
      createController: TestController.new,
    );
    final registry = ProviderRegistry()..registerDefinition(definition);
    expect(() => registry.registerDefinition(definition), throwsArgumentError);
    expect(registry.providerFor(device('one')).id, 'one');
    expect(
      () => registry.providerFor(device('missing')),
      throwsA(isA<RemoteException>()),
    );
  });

  test(
    'protocol timeout cancels the scan and empty searches stay empty',
    () async {
      var closed = false;
      final registry = DiscoveryRegistry()
        ..register(DiscoveryProtocol.ssdp, (_, token, _) async {
          await token.whenCancelled;
          closed = true;
        })
        ..register(DiscoveryProtocol.bonjour, (_, _, _) async {});
      final manager = DiscoveryManager(registry, [
        ObservationIdentifier('one', DiscoveryProtocol.ssdp, 'test'),
        ObservationIdentifier('two', DiscoveryProtocol.bonjour, 'test'),
      ]);
      final reports = <DiscoveryProtocol, ProtocolDiscoveryStatus>{};
      final result = await manager.discover(
        timeout: const Duration(milliseconds: 20),
        onStatus: (status) => reports[status.protocolId] = status,
      );
      expect(closed, isTrue);
      expect(result.failures.single.protocolId, DiscoveryProtocol.ssdp);
      expect(reports[DiscoveryProtocol.bonjour]!.status, DiscoveryStatus.empty);
    },
  );
}
