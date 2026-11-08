import 'dart:async';

import 'package:remote_core/remote_core.dart';

import 'fake_climate.dart';

final class FakeAcDevice extends AcDeviceController {
  final FakeClimate temperature = FakeClimate();

  @override
  final device = RemoteDevice(
    id: 'ac',
    name: 'Air conditioner',
    category: DeviceCategory.airConditioner,
  );

  @override
  DeviceConnectionState get state => DeviceConnectionState.connected;
  @override
  Stream<DeviceConnectionState> get connectionStates => const Stream.empty();
  @override
  List<CapabilityEvidence> get evidence => const [
    CapabilityEvidence(
      RemoteCapability.climate,
      CapabilitySource.driver,
      CapabilityAvailability.verified,
    ),
  ];
  @override
  bool get canWake => false;
  @override
  Future<void> powerOff() async {}
  @override
  Future<void> wake() async {}
  @override
  ({double minimum, double maximum, double step})? get targetTemperatureRange =>
      temperature.targetTemperatureRange;
  @override
  double? get targetTemperature => temperature.targetTemperature;
  @override
  Stream<double?> get targetTemperatureChanges =>
      temperature.targetTemperatureChanges;
  @override
  Stream<double?> get currentTemperatureChanges =>
      temperature.currentTemperatureChanges;
  @override
  Future<void> setTargetTemperature(double celsius) =>
      temperature.setTargetTemperature(celsius);
  @override
  Future<void> setMode(ClimateMode mode) => temperature.setMode(mode);
  @override
  Future<void> setFanSpeed(String speedId) => temperature.setFanSpeed(speedId);
  @override
  Future<void> setSwing(bool enabled) => temperature.setSwing(enabled);
  @override
  Future<void> connect() async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> dispose() => temperature.close();
}
