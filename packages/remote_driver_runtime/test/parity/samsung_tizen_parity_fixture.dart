import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import '../support/samsung_test_credentials.dart';
import '../support/samsung_test_transport.dart';
import 'support/parity_recorder.dart';
import 'support/parity_targets.dart';
import 'support/recording_transport.dart';

/// The Samsung fixture: an authorized secure channel that issues a token.
final class SamsungTizenParityFixture {
  final recorder = ParityRecorder();
  final credentials = SamsungTestCredentials();

  static const targets = ParityTargets(
    channelId: '7',
    inputId: 'HDMI1',
    applicationId: '123',
    accessoryId: '00:11:22:33:44:55',
  );

  RemoteDevice device() => RemoteDevice(
    id: 'samsung.tizen:uuid:parity',
    name: 'Parity Samsung',
    providerId: 'samsung.tizen',
    manufacturer: 'Samsung',
    endpoints: [
      Uri.parse(
        'wss://192.168.1.42:8002/api/v2/channels/samsung.remote.control',
      ),
    ],
    metadata: const {'trustedCertificateDer': 'AQID'},
  );

  Future<TextTransport> open(Uri endpoint, String pin) async {
    recorder.add({
      'open': {'uri': endpoint.toString(), 'pin': pin},
    });
    final transport = SamsungTestTransport()
      ..receive({'event': 'ms.remote.touchEnable'})
      ..receive({
        'event': 'ms.channel.connect',
        'data': {'token': '123456'},
      });
    return RecordingTransport(transport, recorder, 'samsung');
  }

  Future<void> wake() async => recorder.add({'wake': 'wake-on-lan'});
}
