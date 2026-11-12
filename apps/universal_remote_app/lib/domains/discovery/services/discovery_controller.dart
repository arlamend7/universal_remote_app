import 'dart:async';
import 'dart:io';

import '../../diagnostics/models/enums/app_log_level.dart';
import '../../diagnostics/services/diagnostic_logger.dart';
import '../functions/discovery_diagnostic_fields.dart';
import '../functions/discovery_failure_message.dart';
import '../models/connection_issue_type.dart';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

class DiscoveryController {
  DiscoveryController(
    this.manager, {
    required this.acquireNetwork,
    required this.releaseNetwork,
    this.logger,
    this.refreshDriverCatalog,
  });
  final DiscoveryManager manager;
  final unresolved = ValueNotifier<List<DiscoveryObservation>>(const []);
  final Future<void> Function() acquireNetwork;
  final Future<void> Function() releaseNetwork;
  final DiagnosticLogger? logger;
  final Future<void> Function()? refreshDriverCatalog;
  final statuses =
      ValueNotifier<
        Map<
          (String?, String?, DiscoveryProtocol, String?),
          ProtocolDiscoveryStatus
        >
      >(const {});
  int searchId = 0;
  final devices = ValueNotifier<List<RemoteDevice>>([]);
  final recentDevices = ValueNotifier<List<RemoteDevice>>(const []);
  Timer? _presenceExpiry;
  final busy = ValueNotifier(false);
  final error = ValueNotifier<String?>(null);
  final issue = ValueNotifier<ConnectionIssueType?>(null);
  final catalogOffline = ValueNotifier(false);
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
    issue.value = null;
    catalogOffline.value = false;
    devices.value = [];
    _clearPresence();
    unawaited(refreshCatalog());
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
        final failures = reports.map((report) => report.failure!.error);
        final failure = failures.firstWhere(
          (error) => discoveryFailureCode(error) == 'localNetworkDenied',
          orElse: () => failures.first,
        );
        _reportFailure(failure);
      }
    } catch (failure) {
      if (!_disposed && !cancellation.isCancelled) {
        _reportFailure(failure);
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

  void _reportFailure(Object failure) {
    issue.value = switch (discoveryFailureCode(failure)) {
      'localNetworkDenied' => ConnectionIssueType.localNetworkPermissionDenied,
      'noNetworkInterface' ||
      'networkUnreachable' => ConnectionIssueType.networkUnavailable,
      _ => null,
    };
    error.value = discoveryFailureMessage(failure);
  }

  Future<void> refreshCatalog() async {
    final search = searchId;
    try {
      await refreshDriverCatalog?.call();
      if (!_disposed && searchId == search) {
        catalogOffline.value = false;
      }
    } on SocketException {
      _reportCatalogOffline(search);
    } on TimeoutException {
      _reportCatalogOffline(search);
    } on Exception {
      _record('discovery.driverCatalogUnavailable');
    }
  }

  void _reportCatalogOffline(int search) {
    if (_disposed || cancelled || searchId != search) {
      return;
    }
    catalogOffline.value = true;
    _record('discovery.driverCatalogUnavailable');
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
      status.providerLabel,
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
    issue.dispose();
    catalogOffline.dispose();
    statuses.dispose();
    unresolved.dispose();
  }
}
