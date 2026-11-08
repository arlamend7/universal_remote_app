import 'package:remote_core/src/remote_base.dart';

/// A climate device has no TV command contract.
abstract class ACRemoteBase extends RemoteBase {
  ({double minimum, double maximum, double step})? get targetTemperatureRange;
  double? get targetTemperature;
  Stream<double?> get targetTemperatureChanges;
  Stream<double?> get currentTemperatureChanges;
  Future<void> setTargetTemperature(double celsius);
  Future<void> setMode(ClimateMode mode);
  Future<void> setFanSpeed(String speedId);
  Future<void> setSwing(bool enabled);
}

enum ClimateMode { auto, cool, heat, dry, fanOnly }

typedef AcDeviceController = ACRemoteBase;
