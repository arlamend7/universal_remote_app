import 'package:remote_driver_runtime/src/adapters/samsung_tizen/samsung_controller.dart';
import 'package:test/test.dart';

import 'samsung_tizen_parity_fixture.dart';
import 'support/parity_golden.dart';
import 'support/parity_runner.dart';
import 'support/tv_parity_steps.dart';

void main() {
  test(
    'legacy Samsung controller matches the recorded parity baseline',
    () async {
      final fixture = SamsungTizenParityFixture();
      final remote = SamsungController(
        fixture.device(),
        fixture.credentials,
        fixture.wake,
        true,
        openTransport: fixture.open,
      );
      addTearDown(remote.dispose);
      final transcript = await ParityRunner(fixture.recorder)
          .run(remote, tvParitySteps(SamsungTizenParityFixture.targets));
      expectParityGolden('samsung_tizen', transcript);
    },
  );
}
