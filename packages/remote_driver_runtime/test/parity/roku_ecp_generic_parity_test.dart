import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';
import 'package:test/test.dart';

import '../adapters/lg_webos/support/memory_credentials.dart';
import 'generic_parity_controller.dart';
import 'roku_ecp_parity_server.dart';
import 'support/parity_golden.dart';
import 'support/parity_recorder.dart';
import 'support/parity_runner.dart';
import 'support/parity_targets.dart';
import 'support/tv_parity_steps.dart';

void main() {
  test('the Roku ECP integration matches the legacy baseline', () async {
    final recorder = ParityRecorder();
    final server = RokuEcpParityServer(recorder);
    await server.start();
    addTearDown(server.close);
    final remote = genericParityController(
      'roku-ecp/roku-supported',
      RokuEcpEngine(),
      RemoteDevice(
        id: 'roku.ecp:PARITY01',
        name: 'Parity Roku',
        providerId: 'roku.ecp',
        endpoints: [server.endpoint],
      ),
      MemoryCredentials(),
      recorder,
    );
    addTearDown(remote.dispose);
    final transcript = await ParityRunner(recorder).run(
      remote,
      tvParitySteps(
        const ParityTargets(
          channelId: '7.1',
          inputId: 'tvinput.hdmi1',
          applicationId: '12',
          accessoryId: '00:11:22:33:44:55',
        ),
      ),
    );
    expectParityGolden('roku_ecp', transcript);
    expect(remote.device.category, DeviceCategory.television);
  });
}
