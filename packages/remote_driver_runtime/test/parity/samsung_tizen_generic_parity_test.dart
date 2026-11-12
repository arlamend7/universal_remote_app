import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';
import 'package:test/test.dart';

import 'generic_parity_controller.dart';
import 'samsung_tizen_parity_fixture.dart';
import 'support/parity_golden.dart';
import 'support/parity_runner.dart';
import 'support/tv_parity_steps.dart';

void main() {
  test('the Samsung Tizen integration matches the legacy baseline', () async {
    final fixture = SamsungTizenParityFixture();
    final device = fixture.device();
    final remote = genericParityController(
      'samsung-tizen/tizen-supported',
      SamsungChannelEngine(openTransport: fixture.open),
      copyDevice(
        device,
        metadata: {...device.metadata, 'macAddress': 'AA:BB:CC:DD:EE:FF'},
      ),
      fixture.credentials,
      fixture.recorder,
    );
    addTearDown(remote.dispose);
    final transcript = await ParityRunner(fixture.recorder)
        .run(remote, tvParitySteps(SamsungTizenParityFixture.targets));
    expectParityGolden('samsung_tizen', transcript);
  });
}
