import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/roku_ecp.dart';
import 'package:remote_driver_runtime/src/adapters/roku/roku_controller.dart';
import 'package:test/test.dart';

import 'roku_ecp_parity_server.dart';
import 'support/parity_golden.dart';
import 'support/parity_recorder.dart';
import 'support/parity_runner.dart';
import 'support/parity_targets.dart';
import 'support/tv_parity_steps.dart';

const _targets = ParityTargets(
  channelId: '7.1',
  inputId: 'tvinput.hdmi1',
  applicationId: '12',
  accessoryId: '00:11:22:33:44:55',
);

void main() {
  test('legacy Roku controller matches the recorded parity baseline', () async {
    final recorder = ParityRecorder();
    final server = RokuEcpParityServer(recorder);
    await server.start();
    addTearDown(server.close);
    final device = RemoteDevice(
      id: 'roku.ecp:PARITY01',
      name: 'Parity Roku',
      providerId: 'roku.ecp',
      endpoints: [server.endpoint],
    );
    final remote = RokuController(device, RokuEcpClient(server.endpoint));
    addTearDown(remote.dispose);
    final transcript = await ParityRunner(recorder)
        .run(remote, tvParitySteps(_targets));
    expectParityGolden('roku_ecp', transcript);
  });
}
