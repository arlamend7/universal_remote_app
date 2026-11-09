import 'dart:async';
import 'dart:io';

import 'package:multicast_dns/multicast_dns.dart';
import 'package:remote_core/remote_core.dart';

final class MdnsDiscovery {
  const MdnsDiscovery();

  Future<void> search(
    String service,
    DiscoveryCancellation cancellation,
    Future<void> Function(DiscoveryObservation) observe,
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
    final receiveFailure = Completer<void>();
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
        return;
      }
      await Future.any<void>([
        receiveFailure.future,
        _discover(client, service, cancellation, observe),
        cancellation.whenCancelled,
      ]);
    } finally {
      client.stop();
      // multicast_dns.stop() is a no-op when start failed after binding.
      for (final socket in sockets) {
        socket.close();
      }
    }
  }

  Future<void> _discover(
    MDnsClient client,
    String service,
    DiscoveryCancellation cancellation,
    Future<void> Function(DiscoveryObservation) observe,
  ) async {
    final records = await _operation(
      'mdns.ptr',
      () => client
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer('$service.local'),
            timeout: const Duration(seconds: 2),
          )
          .take(32)
          .toList(),
    );
    if (cancellation.isCancelled) {
      return;
    }
    cancellation.record('mdns.pointerRecords', records.length);
    final instances = records
        .map((record) => record.domainName)
        .toSet()
        .toList();
    const batchSize = 8;
    for (var index = 0; index < instances.length; index += batchSize) {
      if (cancellation.isCancelled) {
        return;
      }
      await Future.wait(
        instances
            .skip(index)
            .take(batchSize)
            .map(
              (instance) => _resolveAndPublish(
                client,
                service,
                instance,
                cancellation,
                observe,
              ),
            ),
      );
    }
  }

  Future<void> _resolveAndPublish(
    MDnsClient client,
    String service,
    String instance,
    DiscoveryCancellation cancellation,
    Future<void> Function(DiscoveryObservation) observe,
  ) async {
    final observation = await _resolve(client, service, instance, cancellation);
    if (observation != null && !cancellation.isCancelled) {
      await observe(observation);
    }
  }

  Future<DiscoveryObservation?> _resolve(
    MDnsClient client,
    String service,
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
    if (cancellation.isCancelled || server == null || server.port <= 0) {
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
    return DiscoveryObservation(
      protocolId: DiscoveryProtocol.bonjour,
      serviceType: service,
      endpoint: Uri(
        scheme: 'tcp',
        host: address.address.address,
        port: server.port,
      ),
      metadata: {'name': instance.split('.$service.').first.trim()},
    );
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
}
