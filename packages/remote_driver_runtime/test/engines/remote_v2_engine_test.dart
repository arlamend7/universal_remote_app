import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';
import 'package:remote_driver_runtime/remote_v2.dart';
import 'package:test/test.dart';

import '../parity/android_tv_parity_server.dart';
import '../parity/support/parity_recorder.dart';
import 'engine_test_context.dart';

void main() {
  test(
    'reuses the pinned identity, negotiates features and sends codes',
    () async {
      final recorder = ParityRecorder();
      final [tv, client] = await Future.wait([
        ClientIdentity.generate(),
        ClientIdentity.generate(),
      ]);
      final server = AndroidTvParityServer(recorder);
      await server.start(tv, client);
      addTearDown(server.close);
      final engine = RemoteV2Engine(portOverride: server.port);
      final context = EngineTestContext(
        RemoteDevice(
          id: 'android-tv-engine',
          name: 'TV',
          providerId: 'android.tv',
          endpoints: [Uri(scheme: 'tls', host: '127.0.0.1', port: 6466)],
        ),
        connection: const {'operatingSystem': 'Android TV'},
      );
      await context.credentials.write(
        'android-tv-engine',
        PairedIdentity(
          client,
          PairingProof.fingerprint(tv.certificateDer),
        ).encode(),
      );
      final session = await engine.open(context.build(engine));
      addTearDown(session.close);
      expect(
        session.verifiedPeerIdentity,
        PairingProof.fingerprint(tv.certificateDer),
      );
      expect(session.facts['feature.keys'], 'true');
      expect(session.facts['feature.ime'], 'true');
      expect(session.facts['feature.app-links'], 'true');
      expect(session.software?.operatingSystem, 'Android TV');
      expect(session.software?.protocolVersion, 'Remote v2');
      await session.execute(
        engine.compile(
          OperationMapping(
            operation: 'key-mute',
            kind: 'remote-v2.key',
            parameters: const {'code': 164},
          ),
        ),
        const {},
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(recorder.drain().last, {
        'remoteV2': {
          '10': {'1': 164, '2': 3},
        },
      });
      await expectLater(
        session.execute(
          engine.compile(
            OperationMapping(
              operation: 'launch-application',
              kind: 'remote-v2.app-link',
            ),
          ),
          const {'target': 'javascript:alert(1)'},
        ),
        throwsA(
          isA<RemoteException>().having((e) => e.code, 'code', 'appLink'),
        ),
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
