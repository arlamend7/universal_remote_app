import 'dart:async';

import 'package:remote_core/src/device.dart';
import 'package:remote_core/src/discovery.dart';
import 'package:remote_core/src/remote_base.dart';

/// A provider owns the meaning of its connection configuration and failures.
abstract interface class DeviceConnectionPolicy {
  DeviceCategory get category;
  bool sameConnection(RemoteDevice previous, RemoteDevice next);
  bool canRetryAfterWake(Object error);
  bool canReviewCertificate(RemoteDevice device, String? errorCode);
  RemoteDevice trustCertificate(RemoteDevice device, String certificate);
  RemoteDevice mergeDiscovered(RemoteDevice saved, RemoteDevice discovered);
}

abstract interface class DeviceProvider {
  String get id;
  bool supports(RemoteDevice device);
  Future<List<RemoteDevice>> discover(DiscoveryCancellation cancellation);
  DeviceController createController(RemoteDevice device);
}

/// An integration that can wake a configured device without an active session.
abstract interface class DeviceWakeProvider {
  bool canWakeDevice(RemoteDevice device);
  Future<void> wakeDevice(RemoteDevice device);
}

abstract interface class IncrementalDiscoveryProvider {
  Future<List<RemoteDevice>> discoverIncrementally(
    DiscoveryCancellation cancellation,
    void Function(RemoteDevice) onDevice,
  );
}

abstract interface class ManualDeviceProvider {
  ManualDeviceFactory get manualDeviceFactory;
  DeviceNetworkConfiguration networkConfiguration(RemoteDevice device);
}

typedef ManualDeviceFactory = RemoteDevice Function({
  required String address,
  required String name,
  required bool legacy,
  required bool allowInsecurePointer,
  String? certificate,
  String? mac,
  String? broadcast,
  RemoteDevice? existing,
});
