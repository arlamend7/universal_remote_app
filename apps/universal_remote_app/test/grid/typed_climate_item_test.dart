import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

import '../support/fake_ac_device.dart';

void main() {
  test(
    'the typed AC item changes climate state and rejects unsupported values',
    () async {
      final device = FakeAcDevice();
      addTearDown(device.dispose);
      final updates = expectLater(
        device.temperature.targetTemperatureChanges,
        emits(24),
      );
      await AcItems.targetTemperature.commit(device, 24);
      await updates;
      expect(device.temperature.targetTemperature, 24);
      await expectLater(
        AcItems.targetTemperature.commit(device, 31),
        throwsA(
          isA<RemoteException>().having(
            (error) => error.code,
            'code',
            'temperature',
          ),
        ),
      );
      expect(device.temperature.targetTemperature, 24);
    },
  );
}
