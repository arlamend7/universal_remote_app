import 'dart:async';

import 'package:remote_core/remote_core.dart';

final class FakeClimate {
  final _updates = StreamController<double?>.broadcast();
  double? _target = 22;
  double? get targetTemperature => _target;
  ({double minimum, double maximum, double step}) get targetTemperatureRange =>
      (minimum: 16, maximum: 30, step: .5);
  Stream<double?> get targetTemperatureChanges => _updates.stream;
  Stream<double?> get currentTemperatureChanges => const Stream.empty();
  Future<void> setTargetTemperature(double celsius) async {
    _target = celsius;
    _updates.add(celsius);
  }

  Future<void> setMode(ClimateMode mode) async {}
  Future<void> setFanSpeed(String speedId) async {}
  Future<void> setSwing(bool enabled) async {}
  Future<void> close() => _updates.close();
}
