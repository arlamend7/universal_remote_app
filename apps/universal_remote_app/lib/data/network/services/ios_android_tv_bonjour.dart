import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:remote_core/remote_core.dart';

final class IosAndroidTvBonjour {
  IosAndroidTvBonjour({
    this.channel = const MethodChannel(
      'br.net.devcom.universal_remote/discovery',
    ),
  });

  final MethodChannel channel;
  int _nextRequest = 0;

  Future<List<({String name, String address, int port})>> browse(
    DiscoveryCancellation cancellation,
  ) async {
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
      final rows = await channel.invokeListMethod<Object?>(
        'browseAndroidTV',
        id,
      );
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

  ({String name, String address, int port}) _parse(Object? row) {
    if (row case {
      'name': String name,
      'address': String address,
      'port': int port,
    }) {
      final ip = InternetAddress.tryParse(address);
      if (ip != null && !ip.isLoopback && !ip.isMulticast && port == 6466) {
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
      await channel.invokeMethod<void>('cancelAndroidTV', id);
    } on PlatformException {
      // The native deadline still closes the browser if cancellation fails.
    } on MissingPluginException {
      // A missing channel has no browser to cancel.
    }
  }
}
