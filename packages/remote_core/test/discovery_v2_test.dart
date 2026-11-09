import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:test/test.dart';

import 'support/observation_identifier.dart';

void main() {
  test(
    'searches sharing a protocol and other protocols can fail independently',
    () async {
      final started = Completer<void>();
      var scans = 0;
      final endpoint = Uri.parse('tcp://192.168.1.20:6466');
      final protocols = DiscoveryRegistry()
        ..register(DiscoveryProtocol.ssdp, (target, token, observe) async {
          scans++;
          await started.future;
          await observe(
            DiscoveryObservation(
              protocolId: DiscoveryProtocol.ssdp,
              serviceType: target,
              endpoint: endpoint,
            ),
          );
        })
        ..register(DiscoveryProtocol.bonjour, (_, _, _) async {
          started.complete();
          throw StateError('Unavailable');
        });
      final manager = DiscoveryManager(protocols, [
        ObservationIdentifier('one', DiscoveryProtocol.ssdp, 'tv'),
        ObservationIdentifier('two', DiscoveryProtocol.ssdp, 'TV'),
        ObservationIdentifier('three', DiscoveryProtocol.ssdp, 'tv'),
        ObservationIdentifier('four', DiscoveryProtocol.bonjour, 'tv'),
      ]);
      final result = await manager.discover();
      expect(scans, 3);
      expect(result.devices, hasLength(3));
      expect(result.failures.single.protocolId, DiscoveryProtocol.bonjour);
      expect(
        () => protocols.register(DiscoveryProtocol.ssdp, (_, _, _) async {}),
        throwsArgumentError,
      );
    },
  );

  test('stream updates a device while another SSDP search fails', () async {
    final failingStarted = Completer<void>();
    final releaseFailure = Completer<void>();
    final endpoint = Uri.parse('tcp://192.168.1.20:6466');
    final registry = DiscoveryRegistry()
      ..register(DiscoveryProtocol.ssdp, (service, token, observe) async {
        if (service == 'broken') {
          failingStarted.complete();
          await releaseFailure.future;
          throw StateError('Unavailable');
        }
        await failingStarted.future;
        for (final name in ['Original', 'Updated']) {
          await observe(
            DiscoveryObservation(
              protocolId: DiscoveryProtocol.ssdp,
              serviceType: service,
              endpoint: endpoint,
              metadata: {'name': name},
            ),
          );
        }
      });
    final manager = DiscoveryManager(registry, [
      ObservationIdentifier('working', DiscoveryProtocol.ssdp, 'working'),
      ObservationIdentifier('broken', DiscoveryProtocol.ssdp, 'broken'),
    ]);
    final reports = <String?, ProtocolDiscoveryStatus>{};
    final names = <String>[];
    final cancellation = DiscoveryCancellation();
    await for (final devices in manager.watch(
      cancellation: cancellation,
      onStatus: (report) => reports[report.providerId] = report,
    )) {
      names.add(devices.single.name);
      if (names.length == 2) {
        releaseFailure.complete();
      }
    }
    expect(cancellation.isCancelled, isFalse);
    expect(names, ['Original', 'Updated']);
    expect(reports['working']!.status, DiscoveryStatus.success);
    expect(reports['working']!.deviceCount, 1);
    expect(reports['broken']!.status, DiscoveryStatus.failed);
  });

  test(
    'cancel waits for cooperative cleanup and drops late observations',
    () async {
      final started = Completer<void>();
      final cancelled = DiscoveryCancellation();
      var closed = false;
      final protocols = DiscoveryRegistry()
        ..register(DiscoveryProtocol.ssdp, (target, token, observe) async {
          started.complete();
          await token.whenCancelled;
          await observe(
            DiscoveryObservation(
              protocolId: DiscoveryProtocol.ssdp,
              serviceType: target,
              endpoint: Uri.parse('udp://192.168.1.20'),
            ),
          );
          closed = true;
        });
      final manager = DiscoveryManager(protocols, [
        ObservationIdentifier('one', DiscoveryProtocol.ssdp, 'tv'),
      ]);
      final result = manager.discover(cancellation: cancelled);
      await started.future;
      cancelled.cancel();
      expect((await result).devices, isEmpty);
      expect(closed, isTrue);
    },
  );

  test('same address and name cannot override provider or peer identity', () {
    RemoteDevice device(
      String id,
      String provider,
      String address, [
      String? identity,
    ]) => RemoteDevice(
      id: id,
      name: 'Living room',
      providerId: provider,
      endpoints: [Uri.parse('tls://$address:6466')],
      metadata: {if (identity != null) 'verifiedPeerIdentity': identity},
    );
    const resolver = DeviceIdentifierResolver();
    final first = device('one', 'android.tv', '192.168.1.10', 'peer1');
    expect(
      resolver.same(
        first,
        device('two', 'android.tv', '192.168.1.11', 'peer1'),
      ),
      isTrue,
    );
    expect(
      resolver.same(
        first,
        device('one', 'android.tv', '192.168.1.10', 'peer2'),
      ),
      isFalse,
    );
    expect(
      resolver.same(first, device('one', 'lg.webos', '192.168.1.10', 'peer1')),
      isFalse,
    );
    expect(
      resolver.same(
        device('one', 'android.tv', '192.168.1.10'),
        device('two', 'android.tv', '192.168.1.10'),
      ),
      isFalse,
    );
  });

  test('empty evidence and tentative matches are explicit', () {
    expect(
      () => DiscoveryObservation(
        protocolId: DiscoveryProtocol.ssdp,
        serviceType: '',
      ),
      throwsArgumentError,
    );
    expect(
      () => DiscoveryRequirements({
        DiscoveryProtocol.ssdp: {''},
      }),
      throwsArgumentError,
    );
    final observation = DiscoveryObservation(
      protocolId: DiscoveryProtocol.ssdp,
      serviceType: 'tv',
    );
    final match = ProviderMatch(
      ConnectionProfile(
        RemoteDevice(id: 'pending', name: 'Unresolved', providerId: 'test'),
        confirmed: false,
      ),
      observation,
    );
    expect(match.confirmed, isFalse);
    expect(observation.endpoint, isNull);
  });
}
