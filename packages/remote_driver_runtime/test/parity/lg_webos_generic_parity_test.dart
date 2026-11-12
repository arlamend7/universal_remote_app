import 'package:remote_driver_runtime/integrations.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';
import 'package:test/test.dart';

import '../controller/static_integration_planner.dart';
import 'lg_webos_conditional_scenario.dart';
import 'lg_webos_parity_fixture.dart';
import 'support/integration_files.dart';
import 'support/parity_golden.dart';
import 'support/parity_runner.dart';
import 'support/software_improvement.dart';
import 'support/tv_parity_steps.dart';

GenericTvController lgController(LgWebOsParityFixture fixture, String folder) {
  final definition = IntegrationDefinition.compile(
    integrationFiles(folder),
    ProtocolEngineRegistry([SsapEngine(connector: fixture.connect)]),
  );
  return GenericTvController(
    fixture.device(),
    planner: StaticIntegrationPlanner(
      IntegrationPlan(definition, definition.manifest.bootstrapProfile),
    ),
    credentials: fixture.credentials,
    wakeSender: (mac, broadcast) async =>
        fixture.recorder.add({'wake': 'wake-on-lan'}),
  );
}

void main() {
  test('the LG webOS integration matches the legacy baseline', () async {
    final fixture = LgWebOsParityFixture();
    final remote = lgController(fixture, 'lg-webos/webos-legacy');
    addTearDown(remote.dispose);
    final transcript = await ParityRunner(fixture.recorder)
        .run(remote, tvParitySteps(LgWebOsParityFixture.targets));
    expectParityGolden(
      'lg_webos',
      transcript,
      improvements: {'software': softwareImprovement('5.0')},
    );
  });

  test('LG webOS 22+ conditional capabilities match the baseline', () async {
    final fixture = LgWebOsParityFixture(overrides: lgConditionalOverrides);
    final remote = lgController(fixture, 'lg-webos/webos-22-plus');
    addTearDown(remote.dispose);
    final steps = [
      for (final step in tvParitySteps(LgWebOsParityFixture.targets))
        if (lgConditionalSteps.contains(step.name)) step,
    ];
    final transcript = await ParityRunner(fixture.recorder).run(remote, steps);
    expectParityGolden(
      'lg_webos_conditional',
      transcript,
      improvements: {'software': softwareImprovement('7.0')},
    );
  });
}
