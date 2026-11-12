import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/integrations.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';
import 'package:remote_driver_runtime/remote_v2.dart';
import 'package:test/test.dart';

import '../../../parity/android_tv_parity_server.dart';
import '../../../parity/generic_parity_controller.dart';
import '../../../parity/support/parity_recorder.dart';
import '../../../support/memory_credentials.dart';

/// A generic controller for `android-tv/remote-v2`, already paired with a
/// loopback TV that reports the given features, device info and audio mode.
Future<
  ({
    GenericTvController remote,
    ParityRecorder recorder,
    AndroidTvParityServer server,
  })
>
pairedAndroidTv({
  int features = AndroidTvParityServer.defaultFeatures,
  Map<int, Object>? deviceInfo,
  int? audioMode = 2,
  String id = 'android-tv-paired',
  String? manufacturer,
}) async {
  final recorder = ParityRecorder();
  final [tv, client] = await Future.wait([
    ClientIdentity.generate(),
    ClientIdentity.generate(),
  ]);
  final server = AndroidTvParityServer(
    recorder,
    features: features,
    deviceInfo: deviceInfo,
    audioMode: audioMode,
  );
  await server.start(tv, client);
  addTearDown(server.close);
  final credentials = MemoryCredentials();
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
      name: 'Living Room TV',
      providerId: 'android.tv',
      manufacturer: manufacturer,
      endpoints: [Uri(scheme: 'tls', host: '127.0.0.1', port: 6466)],
    ),
    credentials,
    recorder,
  );
  addTearDown(remote.dispose);
  return (remote: remote, recorder: recorder, server: server);
}
