import 'dart:async';

import '../../diagnostics/models/enums/app_log_level.dart';
import '../../diagnostics/services/diagnostic_logger.dart';
import '../functions/discovery_diagnostic_fields.dart';
import '../functions/discovery_failure_message.dart';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

class DiscoveryController {
  DiscoveryController(
    this.manager, {
    required this.acquireNetwork,
    required this.releaseNetwork,
    this.logger,
  });
  final DiscoveryManager manager;
  final unresolved = ValueNotifier<List<DiscoveryObservation>>(const []);
  final Future<void> Function() acquireNetwork;
  final Future<void> Function() releaseNetwork;
  final DiagnosticLogger? logger;
  final statuses =
      ValueNotifier<
        Map<
          (ProviderIdentity, String?, DiscoveryProtocol, String?),
          ProtocolDiscoveryStatus
        >
      >(const {});
  int searchId = 0;
  final devices = ValueNotifier<List<RemoteDevice>>([]);
  final recentDevices = ValueNotifier<List<RemoteDevice>>(const []);
  Timer? _presenceExpiry;
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
    unresolved.value = const [];
    busy.value = true;
    _record('discovery.started');
    error.value = null;
    devices.value = [];
    _clearPresence();
    try {
      await acquireNetwork();
      if (cancellation.isCancelled) {
        return;
      }
      await _discover(cancellation);
      if (_disposed || cancellation.isCancelled) {
        return;
      }
      final reports = statuses.value.values;
      if (reports.isNotEmpty &&
          reports.every((report) => report.status == DiscoveryStatus.failed)) {
        error.value = discoveryFailureMessage(reports.first.failure!.error);
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

  Future<void> _discover(DiscoveryCancellation cancellation) async {
    final updates = manager.watch(
      cancellation: cancellation,
      onStatus: (report) => _updateStatus(report, cancellation),
      onUnresolved: (observation) {
        if (!_disposed &&
            !cancellation.isCancelled &&
            unresolved.value.length < 128) {
          unresolved.value = [...unresolved.value, observation];
        }
      },
    );
    await for (final found in updates) {
      _publish(found, cancellation);
    }
  }

  void _updateStatus(
    ProtocolDiscoveryStatus status,
    DiscoveryCancellation cancellation,
  ) {
    _record('discovery.protocol', discoveryDiagnosticFields(status));
    if (_disposed || cancellation.isCancelled) {
      return;
    }
    final key = (
      status.provider,
      status.providerId,
      status.protocolId,
      status.serviceType,
    );
    statuses.value = {...statuses.value, key: status};
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
    recentDevices.value = found;
    _presenceExpiry?.cancel();
    if (found.isNotEmpty) {
      _presenceExpiry = Timer(const Duration(seconds: 45), _clearPresence);
    }
  }

  void _clearPresence() {
    _presenceExpiry?.cancel();
    _presenceExpiry = null;
    recentDevices.value = const [];
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
    unresolved.value = const [];
    statuses.value = const {};
  }

  void dispose() {
    _disposed = true;
    cancel();
    _presenceExpiry?.cancel();
    recentDevices.dispose();
    devices.dispose();
    busy.dispose();
    error.dispose();
    statuses.dispose();
    unresolved.dispose();
  }
}
