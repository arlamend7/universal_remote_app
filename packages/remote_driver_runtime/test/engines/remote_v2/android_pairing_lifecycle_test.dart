import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/remote_v2.dart';
import 'package:test/test.dart';

import 'support/scripted_pairing_tv.dart';

void main() {
  late ClientIdentity tv;
  late ClientIdentity client;

  setUpAll(() async {
    [tv, client] = await Future.wait([
      ClientIdentity.generate(),
      ClientIdentity.generate(),
    ]);
  });

  String validCode() =>
      Iterable.generate(
        256,
        (byte) => '${byte.toRadixString(16).padLeft(2, '0')}a1b2',
      ).firstWhere(
        (code) =>
            PairingProof.forCode(
              code,
              client.certificateDer,
              tv.certificateDer,
            ) !=
            null,
      );

  Future<(ScriptedPairingTv, AndroidPairing)> start({
    Map<int, PairingReply> replies = const {},
    Duration codeTimeout = const Duration(seconds: 5),
  }) async {
    final server = ScriptedPairingTv(tv, client, replies: replies);
    await server.start();
    addTearDown(server.close);
    final pairing = AndroidPairing(
      '127.0.0.1',
      client,
      port: server.port,
      codeTimeout: codeTimeout,
      stepTimeout: const Duration(milliseconds: 300),
    );
    addTearDown(pairing.close);
    return (server, pairing);
  }

  Matcher failsWith(String code) =>
      throwsA(isA<RemoteException>().having((e) => e.code, 'code', code));

  test('a valid code pins the TV certificate', () async {
    final (server, pairing) = await start();
    final identity = await pairing.run(() {
      expect(pairing.submit('zzzzzz'), isFalse);
      expect(pairing.submit(validCode()), isTrue);
      expect(pairing.submit(validCode()), isFalse);
    });
    expect(identity.fingerprint, PairingProof.fingerprint(tv.certificateDer));
    expect(server.requests, [10, 20, 30, 40]);
  });

  test(
    'a code the TV rejects (BAD_SECRET) is reported as a wrong code',
    () async {
      final (_, pairing) = await start(
        replies: {40: (status: 402, silent: false, close: false)},
      );
      await expectLater(
        pairing.run(() => pairing.submit(validCode())),
        failsWith('pairingCode'),
      );
    },
  );

  for (final status in [400, 401]) {
    test('a refused configuration ($status) is a pairing refusal', () async {
      final (server, pairing) = await start(
        replies: {20: (status: status, silent: false, close: false)},
      );
      var codeRequested = false;
      await expectLater(
        pairing.run(() => codeRequested = true),
        failsWith('pairing'),
      );
      expect(codeRequested, isFalse);
      expect(server.requests, [10, 20]);
    });
  }

  test('a TV that stops answering times out instead of hanging', () async {
    final (_, pairing) = await start(
      replies: {30: (status: 200, silent: true, close: false)},
    );
    await expectLater(pairing.run(() {}), failsWith('timeout'));
  });

  test('an unentered code expires with a pairing timeout', () async {
    final (server, pairing) = await start(
      codeTimeout: const Duration(milliseconds: 200),
    );
    await expectLater(pairing.run(() {}), failsWith('pairingTimeout'));
    expect(server.requests, [10, 20, 30]);
    expect(pairing.submit(validCode()), isFalse);
  });

  test('a TV that closes the connection during pairing is reported', () async {
    final (_, pairing) = await start(
      replies: {40: (status: 200, silent: false, close: true)},
    );
    await expectLater(
      pairing.run(() => pairing.submit(validCode())),
      failsWith('pairing'),
    );
  });

  test('cancelling while the code is shown sends no secret', () async {
    final (server, pairing) = await start();
    await expectLater(pairing.run(pairing.close), failsWith('cancelled'));
    expect(server.requests, [10, 20, 30]);
  });

  test('an unreachable pairing port fails without a credential', () async {
    final server = ScriptedPairingTv(tv, client);
    await server.start();
    final port = server.port;
    await server.close();
    final pairing = AndroidPairing('127.0.0.1', client, port: port);
    addTearDown(pairing.close);
    await expectLater(pairing.run(() {}), throwsA(isA<Object>()));
  });
}
