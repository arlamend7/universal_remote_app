import 'dart:async';

import '../functions/discovery_failure_message.dart';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

class DiscoveryController {
  DiscoveryController(
    this.registry, {
    required this.acquireNetwork,
    required this.releaseNetwork,
  });
  final ProviderRegistry registry;
  final Future<void> Function() acquireNetwork;
  final Future<void> Function() releaseNetwork;
  final devices = ValueNotifier<List<RemoteDevice>>([]);
  final busy = ValueNotifier(false);
  final error = ValueNotifier<String?>(null);
  DiscoveryCancellation? _cancellation;
  bool _disposed = false;
  Future<void>? _searchFuture;
  Future<void> search() {
    if (busy.value || _disposed) {
      return _searchFuture ?? Future.value();
    }
    return _searchFuture = _search();
  }

  Future<void> stop() async {
    cancel();
    await _searchFuture;
  }

  Future<void> _search() async {
    if (busy.value || _disposed) {
      return;
    }
    final cancellation = DiscoveryCancellation();
    _cancellation = cancellation;
    busy.value = true;
    error.value = null;
    devices.value = [];
    try {
      await acquireNetwork();
      if (cancellation.isCancelled) {
        return;
      }
      final result = await registry.discover(
        cancellation: cancellation,
        onDevices: (found) => _publish(found, cancellation),
      );
      if (_disposed || cancellation.isCancelled) {
        return;
      }
      if (result.failures.isNotEmpty) {
        error.value = discoveryFailureMessage(result.failures.first.error);
      }
    } catch (failure) {
      if (!_disposed && !cancellation.isCancelled) {
        error.value = discoveryFailureMessage(failure);
      }
    } finally {
      await _releaseNetwork();
      if (!_disposed) {
        busy.value = false;
      }
    }
  }

  void _publish(List<RemoteDevice> found, DiscoveryCancellation cancellation) {
    if (_disposed || cancellation.isCancelled) {
      return;
    }
    devices.value = found;
  }

  Future<void> _releaseNetwork() async {
    try {
      await releaseNetwork();
    } catch (_) {
      _reportReleaseFailure();
    }
  }

  void _reportReleaseFailure() {
    if (_disposed) {
      return;
    }
    error.value = 'Could not release discovery resources.';
  }

  void cancel() => _cancellation?.cancel();
  void dispose() {
    _disposed = true;
    cancel();
    devices.dispose();
    busy.dispose();
    error.dispose();
  }
}
