import 'package:remote_core/src/device.dart';

/// A provider owns the meaning of its connection configuration and failures.
abstract interface class DeviceConnectionPolicy {
  DeviceCategory get category;
  bool sameConnection(RemoteDevice previous, RemoteDevice next);
  bool canRetryAfterWake(Object error);
  bool canReviewCertificate(RemoteDevice device, String? errorCode);
  RemoteDevice trustCertificate(RemoteDevice device, String certificate);
  RemoteDevice mergeDiscovered(RemoteDevice saved, RemoteDevice discovered);
}

/// An integration that can wake a configured device without an active session.
abstract interface class DeviceWakeProvider {
  bool canWakeDevice(RemoteDevice device);
  Future<void> wakeDevice(RemoteDevice device);
}

abstract interface class ManualDeviceProvider {
  ManualDeviceFactory get manualDeviceFactory;
  String get manualSetupLabel;
  bool get showsAdvancedSetup;
  DeviceNetworkConfiguration networkConfiguration(RemoteDevice device);
}

typedef ManualDeviceSetup = ({
  String label,
  bool showsAdvancedSetup,
  ManualDeviceFactory factory,
});

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
