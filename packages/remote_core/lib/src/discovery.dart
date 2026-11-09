import 'dart:async';

import 'package:remote_core/src/device.dart';

import 'devices/models/registered_device.dart';
import 'discovery/device_identifier_resolver.dart';
import 'discovery/discovery_protocol.dart';
import 'discovery/protocol_discovery_status.dart';

/// Cooperative cancellation; providers must release discovery resources.
final class DiscoveryCancellation {
  final _cancelled = Completer<void>();
  final _observations = <String, int>{};

  Map<String, int> get observations => Map.unmodifiable(_observations);

  /// Records a protocol-owned stage without logging network or device data.
  void record(String stage, [int count = 1]) {
    if (isCancelled) {
      return;
    }
    _observations.update(
      stage,
      (value) => value + count,
      ifAbsent: () => count,
    );
  }

  bool get isCancelled => _cancelled.isCompleted;
  Future<void> get whenCancelled => _cancelled.future;
  void cancel() {
    if (!_cancelled.isCompleted) {
      _cancelled.complete();
    }
  }
}

final class DiscoveryFailure {
  const DiscoveryFailure(this.protocolId, this.error);
  final DiscoveryProtocol protocolId;
  final Object error;
}

final class DiscoveryResult {
  DiscoveryResult(
    Iterable<ProtocolDiscoveryStatus> reports,
    Iterable<RegisteredDevice> registeredDevices,
  ) : reports = List.unmodifiable(reports),
      registeredDevices = List.unmodifiable(registeredDevices);

  final List<ProtocolDiscoveryStatus> reports;
  List<DiscoveryFailure> get failures => List.unmodifiable(
    reports.map((report) => report.failure).whereType<DiscoveryFailure>(),
  );
  final List<RegisteredDevice> registeredDevices;
  List<RemoteDevice> get devices => List.unmodifiable(
    registeredDevices.map((device) => device.preferredProfile.device),
  );
}

/// Applies a verified rediscovery to the existing profile without changing its trust.
final class DiscoveryProfiles {
  DiscoveryProfiles({required this.profiles, required this.update});
  final _resolver = const DeviceIdentifierResolver();
  final Iterable<RemoteDevice> Function() profiles;
  final Future<void> Function(
    String id,
    RemoteDevice? Function(RemoteDevice) change,
  )
  update;
  RemoteDevice? registered(RemoteDevice candidate) => profiles()
      .where((device) => _resolver.same(device, candidate))
      .firstOrNull;
  Future<void> updateAddress(RemoteDevice candidate) async {
    final existing = registered(candidate);
    final endpoint = candidate.endpoints.firstOrNull;
    if (existing == null || endpoint == null) {
      return;
    }
    await update(
      existing.id,
      (current) => copyDevice(
        current,
        endpoints: current.endpoints
            .map((old) => old.replace(host: endpoint.host))
            .toList(),
      ),
    );
  }
}
