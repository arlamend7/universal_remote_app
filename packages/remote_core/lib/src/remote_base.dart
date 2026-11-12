import 'dart:async';
import 'dart:io';

import 'package:remote_core/src/device.dart';

import 'devices/models/device_software_information.dart';

/// Common lifecycle and optional capabilities exposed by a provider remote.
abstract class RemoteBase implements RemoteDriver {
  DeviceConnectionState get state;
  List<CapabilityEvidence> get evidence;
  Stream<void> get capabilityChanges => const Stream.empty();

  /// Whether this session has driver evidence that [capability] is usable.
  bool supports(RemoteCapability capability) => evidence.any(
    (item) => item.capability == capability && item.availability.isUsable,
  );

  /// Stable identity established by an authenticated connection, when available.
  String? get verifiedPeerIdentity => null;
  String? get reportedDiscoveryIdentity => null;

  /// Software evidence produced by the current connection attempt.
  DeviceSoftwareInformation? get sessionSoftwareInformation => null;

  bool get canWake;
  Future<void> powerOff();
  Future<void> wake();
}

abstract interface class RemoteDriver {
  RemoteDevice get device;
  Stream<DeviceConnectionState> get connectionStates;
  Future<void> connect();
  Future<void> disconnect();
  Future<void> dispose();
}

/// Optional, read-only lookup from a successfully connected device session.
abstract interface class DeviceWakeAddressSource {
  Future<DeviceWakeAddress?> readWakeAddress();
}

abstract interface class HardwareAddressResolver {
  Future<String?> resolve(InternetAddress address);
}

/// Owns one driver and its state subscription; disposal can be awaited repeatedly.
final class DeviceSession {
  DeviceSession(this.controller);
  final RemoteBase controller;
  StreamSubscription<DeviceConnectionState>? _states;
  StreamSubscription<void>? _capabilities;
  Future<void>? _disposeFuture;
  void observe(
    void Function(DeviceConnectionState) onState, {
    void Function()? onCapabilities,
  }) {
    _states = controller.connectionStates.listen(onState);
    if (onCapabilities != null) {
      _capabilities = controller.capabilityChanges.listen(
        (_) => onCapabilities(),
      );
    }
  }

  Future<void> dispose() => _disposeFuture ??= _dispose();
  Future<void> _dispose() async {
    await _capabilities?.cancel();
    await _states?.cancel();
    _states = null;
    await controller.dispose();
  }
}

enum DisconnectReason { user, poweredOff, connectionLost, suspended }

/// Use resolved driver evidence. Discovery advertisements alone are insufficient.
Set<RemoteCapability> resolvedCapabilities(RemoteBase controller) => {
  for (final item in controller.evidence)
    if (item.availability.isUsable) item.capability,
};
