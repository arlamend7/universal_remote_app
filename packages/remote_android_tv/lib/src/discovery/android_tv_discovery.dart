import 'dart:async';

import 'package:multicast_dns/multicast_dns.dart';
import 'package:remote_core/remote_core.dart';

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
      await client.start();
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
    final instances = records.map((record) => record.domainName).toSet();
    final devices = await Future.wait(
      instances.map((instance) => _resolve(client, providerId, instance)),
    );
    if (cancellation.isCancelled) {
      return [];
    }
    final unique = DeviceIdentity.unique(devices.whereType<RemoteDevice>());
    unique.forEach(onDevice);
    return unique;
  }

  Future<RemoteDevice?> _resolve(
    MDnsClient client,
    String providerId,
    String instance,
  ) async {
    final servers = await client
        .lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(instance),
          timeout: const Duration(seconds: 1),
        )
        .take(1)
        .toList();
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
    final address = addresses.firstOrNull;
    if (address == null) {
      return null;
    }
    final name = instance.split('._androidtvremote2.').first.trim();
    return RemoteDevice(
      id: newProfileId(),
      name: name.isEmpty ? 'Android TV' : name,
      providerId: providerId,
      category: DeviceCategory.television,
      stableIdentity: false,
      endpoints: [
        Uri(scheme: 'tls', host: address.address.address, port: 6466),
      ],
    );
  }
}
