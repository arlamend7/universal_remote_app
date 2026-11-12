import 'package:remote_driver_runtime/tv_provider_adapters.dart';
import 'package:test/test.dart';

import 'lg_webos_parity_fixture.dart';
import 'support/parity_golden.dart';
import 'support/parity_runner.dart';
import 'support/tv_parity_steps.dart';

void main() {
  test(
    'legacy LG webOS controller matches the recorded parity baseline',
    () async {
      final fixture = LgWebOsParityFixture();
      final provider = LgWebOsProvider(
        credentials: fixture.credentials,
        connector: fixture.connect,
      );
      final remote = provider.createController(fixture.device());
      addTearDown(remote.dispose);
      final transcript = await ParityRunner(fixture.recorder)
          .run(remote, tvParitySteps(LgWebOsParityFixture.targets));
      expectParityGolden('lg_webos', transcript);
    },
  );
}
