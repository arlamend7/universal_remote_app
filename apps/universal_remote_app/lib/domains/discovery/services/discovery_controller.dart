import 'dart:async';

import '../../diagnostics/models/enums/app_log_level.dart';
import '../../diagnostics/services/diagnostic_logger.dart';
import '../functions/discovery_diagnostic_fields.dart';
import '../functions/discovery_failure_message.dart';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

class DiscoveryController {
  DiscoveryController(
    this.registry, {
    required this.acquireNetwork,
    required this.releaseNetwork,
    this.logger,
  });
  final ProviderRegistry registry;
  final Future<void> Function() acquireNetwork;
  final Future<void> Function() releaseNetwork;
  final DiagnosticLogger? logger;
  final statuses = ValueNotifier<Map<String, ProviderDiscoveryStatus>>(
    const {},
  );
  int searchId = 0;
  final devices = ValueNotifier<List<RemoteDevice>>([]);
  final busy = ValueNotifier(false);
  final error = ValueNotifier<String?>(null);
  DiscoveryCancellation? _cancellation;
  bool get cancelled => _cancellation?.isCancelled ?? false;
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
    searchId++;
    final elapsed = Stopwatch()..start();
    statuses.value = const {};
    busy.value = true;
    _record('discovery.started');
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
        onStatus: (status) => _updateStatus(status, cancellation),
      );
      if (_disposed || cancellation.isCancelled) {
        return;
      }
      devices.value = result.devices;
      final reports = statuses.value.values;
      if (reports.isNotEmpty &&
          reports.every((report) => report.status == DiscoveryStatus.failed)) {
        error.value = discoveryFailureMessage(result.failures.first.error);
      }
    } catch (failure) {
      if (!_disposed && !cancellation.isCancelled) {
        error.value = discoveryFailureMessage(failure);
      }
    } finally {
      await _releaseNetwork();
      _record(
        cancellation.isCancelled
            ? 'discovery.cancelled'
            : 'discovery.completed',
        {'durationMs': elapsed.elapsedMilliseconds},
      );
      if (!_disposed) {
        busy.value = false;
      }
    }
  }

  void _updateStatus(
    ProviderDiscoveryStatus status,
    DiscoveryCancellation cancellation,
  ) {
    _record('discovery.provider', discoveryDiagnosticFields(status));
    if (_disposed || cancellation.isCancelled) {
      return;
    }
    statuses.value = {...statuses.value, status.providerId: status};
  }

  void _record(String event, [Map<String, Object> fields = const {}]) {
    logger?.record(
      AppLogLevel.info,
      event,
      fields: {'searchId': searchId, ...fields},
    );
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
    if (_disposed || cancelled || error.value != null) {
      return;
    }
    error.value = 'Could not release discovery resources.';
  }

  void cancel() {
    if (!busy.value) {
      return;
    }
    _cancellation?.cancel();
    if (_disposed) {
      return;
    }
    devices.value = [];
    statuses.value = const {};
  }

  void dispose() {
    _disposed = true;
    cancel();
    devices.dispose();
    busy.dispose();
    error.dispose();
    statuses.dispose();
  }
}
