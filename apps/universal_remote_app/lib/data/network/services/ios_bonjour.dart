import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:remote_core/remote_core.dart';

final class IosBonjour {
  IosBonjour({
    this.channel = const MethodChannel(
      'br.net.devcom.universal_remote/discovery',
    ),
  });

  final MethodChannel channel;
  int _nextRequest = 0;

  Future<List<({String name, String address, int port})>> browse(
    DiscoveryCancellation cancellation, {
    required String service,
  }) async {
    if (cancellation.isCancelled) {
      return [];
    }
    final id = ++_nextRequest;
    var completed = false;
    unawaited(
      cancellation.whenCancelled.then((_) async {
        if (!completed) {
          await _cancel(id);
        }
      }),
    );
    try {
      final rows = await channel.invokeListMethod<Object?>('browseBonjour', {
        'id': id,
        'service': service,
      });
      if (cancellation.isCancelled) {
        return [];
      }
      return (rows ?? []).map(_parse).toList();
    } on PlatformException catch (error) {
      final details = error.details;
      throw DiscoveryOperationFailure(
        details is Map && details['stage'] is String
            ? details['stage'] as String
            : 'bonjour.browse',
        error,
        code: error.code,
        osCode: details is Map ? details['osCode'] as int? : null,
        errorDomain: details is Map ? details['domain'] as String? : null,
      );
    } on MissingPluginException catch (error) {
      throw DiscoveryOperationFailure(
        'bonjour.start',
        error,
        code: 'bonjourUnavailable',
      );
    } finally {
      completed = true;
    }
  }

  Future<void> search(
    String service,
    DiscoveryCancellation cancellation,
    Future<void> Function(DiscoveryObservation) observe,
  ) async {
    final rows = await browse(cancellation, service: service);
    cancellation.record('bonjour.resolved', rows.length);
    for (final row in rows) {
      if (cancellation.isCancelled) {
        return;
      }
      await observe(
        DiscoveryObservation(
          protocolId: DiscoveryProtocol.bonjour,
          serviceType: service,
          endpoint: Uri(scheme: 'tcp', host: row.address, port: row.port),
          metadata: {'name': row.name},
        ),
      );
    }
  }

  ({String name, String address, int port}) _parse(Object? row) {
    if (row case {
      'name': String name,
      'address': String address,
      'port': int port,
    }) {
      final ip = InternetAddress.tryParse(address);
      if (ip != null &&
          !ip.isLoopback &&
          !ip.isMulticast &&
          port > 0 &&
          port <= 65535) {
        return (name: name, address: ip.address, port: port);
      }
    }
    throw const DiscoveryOperationFailure(
      'bonjour.parse',
      FormatException('Invalid Bonjour result'),
      code: 'invalidAdvertisement',
    );
  }

  Future<void> _cancel(int id) async {
    try {
      await channel.invokeMethod<void>('cancelBonjour', id);
    } on PlatformException {
      // The native deadline still closes the browser if cancellation fails.
    } on MissingPluginException {
      // A missing channel has no browser to cancel.
    }
  }
}
