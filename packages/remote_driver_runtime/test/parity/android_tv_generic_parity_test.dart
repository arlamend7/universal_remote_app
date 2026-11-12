import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';
import 'package:remote_driver_runtime/remote_v2.dart';
import 'package:test/test.dart';

import '../support/memory_credentials.dart';
import 'android_tv_parity_server.dart';
import 'generic_parity_controller.dart';
import 'support/parity_golden.dart';
import 'support/parity_recorder.dart';
import 'support/parity_runner.dart';
import 'support/parity_targets.dart';
import 'support/tv_parity_steps.dart';

void main() {
  test('the Android TV integration matches the legacy baseline', () async {
    final recorder = ParityRecorder();
    final [tv, client] = await Future.wait([
      ClientIdentity.generate(),
      ClientIdentity.generate(),
    ]);
    final server = AndroidTvParityServer(recorder);
    await server.start(tv, client);
    addTearDown(server.close);
    final credentials = MemoryCredentials();
    const id = 'android-tv-parity';
    await credentials.write(
      id,
      PairedIdentity(
        client,
        PairingProof.fingerprint(tv.certificateDer),
      ).encode(),
    );
    final remote = genericParityController(
      'android-tv/remote-v2',
      RemoteV2Engine(portOverride: server.port),
      RemoteDevice(
        id: id,
        name: 'Parity Android TV',
        providerId: 'android.tv',
        endpoints: [Uri(scheme: 'tls', host: '127.0.0.1', port: 6466)],
        metadata: const {'macAddress': 'AA:BB:CC:DD:EE:FF'},
      ),
      credentials,
      recorder,
    );
    addTearDown(remote.dispose);
    final transcript =
        await ParityRunner(
          recorder,
          settle: const Duration(milliseconds: 40),
        ).run(
          remote,
          tvParitySteps(
            const ParityTargets(
              channelId: '7',
              inputId: 'HDMI1',
              applicationId: 'com.example.tv',
              accessoryId: '00:11:22:33:44:55',
            ),
          ),
        );
    expectParityGolden('android_tv', transcript);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
