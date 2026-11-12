import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';
import 'package:remote_driver_runtime/remote_v2.dart';
import 'package:test/test.dart';

import '../engine_test_context.dart';
import 'support/scripted_pairing_tv.dart';

void main() {
  late ClientIdentity tv;

  setUpAll(() async => tv = await ClientIdentity.generate());

  Future<int> closedPort() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  Future<(EngineTestContext, Future<EngineSession>)> open(
    Map<int, PairingReply> replies,
  ) async {
    final server = ScriptedPairingTv(
      tv,
      tv,
      replies: replies,
      requireClient: false,
    );
    await server.start();
    addTearDown(server.close);
    final engine = RemoteV2Engine(
      portOverride: await closedPort(),
      pairingPortOverride: server.port,
    );
    final context = EngineTestContext(
      RemoteDevice(
        id: 'android-tv-new',
        name: 'TV',
        providerId: 'android.tv',
        endpoints: [Uri(scheme: 'tls', host: '127.0.0.1', port: 6466)],
      ),
      connection: const {'operatingSystem': 'Android TV'},
    );
    return (context, engine.open(context.build(engine)));
  }

  Future<void> codeShown(EngineTestContext context) async {
    while (context.submit == null) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  test(
    'a code the TV rejects stores no credential and clears the prompt',
    () async {
      final (context, session) = await open({
        40: (status: 402, silent: false, close: false),
      });
      final failure = expectLater(
        session,
        throwsA(
          isA<RemoteException>().having((e) => e.code, 'code', 'pairingCode'),
        ),
      );
      await codeShown(context);
      expect(context.states, [DeviceConnectionState.pairing]);
      // Any locally valid code is forwarded; the scripted TV rejects it.
      final submit = context.submit!;
      var accepted = false;
      for (var byte = 0; byte < 256 && !accepted; byte++) {
        accepted = await submit(
          '${byte.toRadixString(16).padLeft(2, '0')}0000',
        );
      }
      expect(accepted, isTrue);
      await failure;
      expect(context.submit, isNull);
      expect(await context.credentials.read('android-tv-new'), isNull);
    },
  );

  test(
    'a successful pairing stores the pinned identity before connecting',
    () async {
      final (context, session) = await open(const {});
      final connection = expectLater(session, throwsA(isA<Object>()));
      await codeShown(context);
      final submit = context.submit!;
      var accepted = false;
      for (var byte = 0; byte < 256 && !accepted; byte++) {
        accepted = await submit(
          '${byte.toRadixString(16).padLeft(2, '0')}0000',
        );
      }
      await connection;
      final stored = await context.credentials.read('android-tv-new');
      expect(
        PairedIdentity.decode(stored!).fingerprint,
        PairingProof.fingerprint(tv.certificateDer),
      );
      expect(context.submit, isNull);
    },
  );
}
