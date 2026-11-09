import 'dart:async';
import 'dart:io';

import 'package:multicast_dns/multicast_dns.dart';
import 'package:remote_core/remote_core.dart';

import '../security/discover_peer_identity.dart';

final class AndroidTvDiscovery {
  const AndroidTvDiscovery({this.browseBonjour});

  final Future<List<({String name, String address, int port})>> Function(
    DiscoveryCancellation cancellation,
  )?
  browseBonjour;

  static const service = '_androidtvremote2._tcp.local';

  Future<List<RemoteDevice>> discover(
    String providerId,
    DiscoveryCancellation cancellation,
    void Function(RemoteDevice) onDevice,
  ) async {
    if (cancellation.isCancelled) {
      return [];
    }
    if (browseBonjour case final browse?) {
      final records = await browse(cancellation);
      return _bonjourDevices(providerId, records, cancellation, onDevice);
    }
    return _discoverMdns(providerId, cancellation, onDevice);
  }

  Future<List<RemoteDevice>> _discoverMdns(
    String providerId,
    DiscoveryCancellation cancellation,
    void Function(RemoteDevice) onDevice,
  ) async {
    final sockets = <RawDatagramSocket>[];
    final client = MDnsClient(
      rawDatagramSocketFactory:
          (
            host,
            port, {
            reuseAddress = true,
            reusePort = false,
            ttl = 1,
          }) async {
            final socket = await _operation(
              'mdns.bind',
              () => RawDatagramSocket.bind(
                host,
                port,
                reuseAddress: reuseAddress,
                reusePort: reusePort,
                ttl: ttl,
              ),
            );
            sockets.add(socket);
            return socket;
          },
    );
    final receiveFailure = Completer<List<RemoteDevice>>();
    try {
      cancellation.record('mdns.starting');
      await _operation(
        'mdns.join',
        () => client.start(
          onError: (Object error, StackTrace stack) {
            if (!receiveFailure.isCompleted && !cancellation.isCancelled) {
              receiveFailure.completeError(
                DiscoveryOperationFailure('mdns.receive', error),
                stack,
              );
            }
          },
        ),
      );
      cancellation.record('mdns.started');
      if (cancellation.isCancelled) {
        return [];
      }
      return await Future.any([
        receiveFailure.future,
        _discover(client, providerId, cancellation, onDevice),
        cancellation.whenCancelled.then((_) => <RemoteDevice>[]),
      ]);
    } finally {
      client.stop();
      // multicast_dns.stop() is a no-op when start failed after binding.
      for (final socket in sockets) {
        socket.close();
      }
    }
  }

  Future<List<RemoteDevice>> _discover(
    MDnsClient client,
    String providerId,
    DiscoveryCancellation cancellation,
    void Function(RemoteDevice) onDevice,
  ) async {
    final records = await _operation(
      'mdns.ptr',
      () => client
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer(service),
            timeout: const Duration(seconds: 2),
          )
          .take(32)
          .toList(),
    );
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
    final servers = await _operation(
      'mdns.srv',
      () => client
          .lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(instance),
            timeout: const Duration(seconds: 1),
          )
          .take(1)
          .toList(),
    );
    cancellation.record('mdns.serviceRecords', servers.length);
    final server = servers.firstOrNull;
    if (cancellation.isCancelled || server == null || server.port != 6466) {
      return null;
    }
    final addresses = await _operation(
      'mdns.address',
      () => client
          .lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(server.target),
            timeout: const Duration(seconds: 1),
          )
          .take(1)
          .toList(),
    );
    cancellation.record('mdns.addressRecords', addresses.length);
    final address = addresses.firstOrNull;
    if (cancellation.isCancelled || address == null) {
      return null;
    }
    return _device(
      providerId,
      instance.split('._androidtvremote2.').first.trim(),
      address.address.address,
    );
  }

  Future<List<RemoteDevice>> _bonjourDevices(
    String providerId,
    List<({String name, String address, int port})> records,
    DiscoveryCancellation cancellation,
    void Function(RemoteDevice) onDevice,
  ) async {
    if (cancellation.isCancelled) {
      return [];
    }
    cancellation.record('bonjour.resolved', records.length);
    final addresses = <String>{};
    final pending = records
        .where((record) => record.port == 6466 && addresses.add(record.address))
        .map((record) async {
          final device = await _device(providerId, record.name, record.address);
          if (!cancellation.isCancelled) {
            onDevice(device);
          }
          return device;
        });
    final devices = await Future.wait(pending);
    return cancellation.isCancelled ? [] : DeviceIdentity.unique(devices);
  }

  Future<T> _operation<T>(String stage, Future<T> Function() action) async {
    try {
      return await action();
    } on DiscoveryOperationFailure {
      rethrow;
    } catch (error) {
      throw DiscoveryOperationFailure(stage, error);
    }
  }

  Future<RemoteDevice> _device(
    String providerId,
    String name,
    String address,
  ) async {
    final identity = await discoverPeerIdentity(address);
    return RemoteDevice(
      id: identity == null ? newProfileId() : 'android-tv-$identity',
      name: name.isEmpty ? 'Android TV' : name,
      providerId: providerId,
      category: DeviceCategory.television,
      stableIdentity: identity != null,
      metadata: {if (identity != null) 'advertisedPeerIdentity': identity},
      endpoints: [Uri(scheme: 'tls', host: address, port: 6466)],
    );
  }
}
