import 'dart:async';

import 'package:multicast_dns/multicast_dns.dart';
import 'package:remote_core/remote_core.dart';

import '../security/discover_peer_identity.dart';

final class AndroidTvDiscovery {
  const AndroidTvDiscovery();

  static const service = '_androidtvremote2._tcp.local';

  Future<List<RemoteDevice>> discover(
    String providerId,
    DiscoveryCancellation cancellation,
    void Function(RemoteDevice) onDevice,
  ) async {
    if (cancellation.isCancelled) {
      return [];
    }
    final client = MDnsClient();
    try {
      cancellation.record('mdns.starting');
      await client.start();
      cancellation.record('mdns.started');
      if (cancellation.isCancelled) {
        return [];
      }
      return await Future.any([
        _discover(client, providerId, cancellation, onDevice),
        cancellation.whenCancelled.then((_) => <RemoteDevice>[]),
      ]);
    } finally {
      client.stop();
    }
  }

  Future<List<RemoteDevice>> _discover(
    MDnsClient client,
    String providerId,
    DiscoveryCancellation cancellation,
    void Function(RemoteDevice) onDevice,
  ) async {
    final records = await client
        .lookup<PtrResourceRecord>(
          ResourceRecordQuery.serverPointer(service),
          timeout: const Duration(seconds: 2),
        )
        .take(32)
        .toList();
    if (cancellation.isCancelled) {
      return [];
    }
    cancellation.record('mdns.pointerRecords', records.length);
    final instances = records.map((record) => record.domainName).toSet();
    final devices = <RemoteDevice>[];
    await Future.wait(
      instances.map((instance) async {
        final device = await _resolve(
          client,
          providerId,
          instance,
          cancellation,
        );
        if (device == null ||
            cancellation.isCancelled ||
            devices.any((existing) => DeviceIdentity.same(existing, device))) {
          return;
        }
        devices.add(device);
        onDevice(device);
      }),
    );
    return cancellation.isCancelled ? [] : devices;
  }

  Future<RemoteDevice?> _resolve(
    MDnsClient client,
    String providerId,
    String instance,
    DiscoveryCancellation cancellation,
  ) async {
    final servers = await client
        .lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(instance),
          timeout: const Duration(seconds: 1),
        )
        .take(1)
        .toList();
    cancellation.record('mdns.serviceRecords', servers.length);
    final server = servers.firstOrNull;
    if (server == null || server.port != 6466) {
      return null;
    }
    final addresses = await client
        .lookup<IPAddressResourceRecord>(
          ResourceRecordQuery.addressIPv4(server.target),
          timeout: const Duration(seconds: 1),
        )
        .take(1)
        .toList();
    cancellation.record('mdns.addressRecords', addresses.length);
    final address = addresses.firstOrNull;
    if (address == null) {
      return null;
    }
    final identity = await discoverPeerIdentity(address.address.address);
    final name = instance.split('._androidtvremote2.').first.trim();
    return RemoteDevice(
      id: identity == null ? newProfileId() : 'android-tv-$identity',
      name: name.isEmpty ? 'Android TV' : name,
      providerId: providerId,
      category: DeviceCategory.television,
      stableIdentity: identity != null,
      metadata: {if (identity != null) 'advertisedPeerIdentity': identity},
      endpoints: [
        Uri(scheme: 'tls', host: address.address.address, port: 6466),
      ],
    );
  }
}
