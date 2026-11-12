import 'package:remote_driver_runtime/tv_provider_adapters.dart';
import 'package:test/test.dart';

import 'lg_webos_conditional_scenario.dart';
import 'lg_webos_parity_fixture.dart';
import 'support/parity_golden.dart';
import 'support/parity_runner.dart';
import 'support/parity_step.dart';
import 'support/tv_parity_steps.dart';

void main() {
  test('legacy LG webOS conditional capabilities match the baseline', () async {
    final fixture = LgWebOsParityFixture(overrides: lgConditionalOverrides);
    final provider = LgWebOsProvider(
      credentials: fixture.credentials,
      connector: fixture.connect,
    );
    final remote = provider.createController(fixture.device());
    addTearDown(remote.dispose);
    final steps = [
      for (final step in tvParitySteps(LgWebOsParityFixture.targets))
        if (lgConditionalSteps.contains(step.name)) step,
    ];
    final transcript = await ParityRunner(fixture.recorder)
        .run(remote, <ParityStep>[...steps]);
    expectParityGolden('lg_webos_conditional', transcript);
  });
}
