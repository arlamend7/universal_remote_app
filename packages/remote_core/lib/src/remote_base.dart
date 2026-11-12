import 'dart:io';

import 'package:remote_core/src/device.dart';

import 'devices/models/device_software_information.dart';

export 'devices/services/device_session.dart';

/// Common lifecycle and optional capabilities exposed by a provider remote.
abstract class RemoteBase {
  RemoteDevice get device;
  Stream<DeviceConnectionState> get connectionStates;
  Future<void> connect();
  Future<void> disconnect();
  Future<void> dispose();

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

/// Optional, read-only lookup from a successfully connected device session.
abstract interface class DeviceWakeAddressSource {
  Future<DeviceWakeAddress?> readWakeAddress();
}

abstract interface class HardwareAddressResolver {
  Future<String?> resolve(InternetAddress address);
}

enum DisconnectReason { user, poweredOff, connectionLost, suspended }

/// Use resolved driver evidence. Discovery advertisements alone are insufficient.
Set<RemoteCapability> resolvedCapabilities(RemoteBase controller) => {
  for (final item in controller.evidence)
    if (item.availability.isUsable) item.capability,
};
