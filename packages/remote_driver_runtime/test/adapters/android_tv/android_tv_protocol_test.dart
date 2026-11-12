import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:remote_driver_runtime/remote_v2.dart';
import 'package:test/test.dart';
import 'package:remote_core/remote_core.dart';

void main() {
  late ClientIdentity tv;
  late ClientIdentity client;

  setUpAll(() async {
    [tv, client] = await Future.wait([
      ClientIdentity.generate(),
      ClientIdentity.generate(),
    ]);
  });

  Future<SecureServerSocket> listen() => SecureServerSocket.bind(
    InternetAddress.loopbackIPv4,
    0,
    tv.context()..setTrustedCertificatesBytes(utf8.encode(client.certificate)),
    requestClientCertificate: true,
    requireClientCertificate: true,
  );

  test(
    'pairs using a TV code and reconnects with the pinned certificate',
    () async {
      final pairingServer = await listen();
      addTearDown(pairingServer.close);
      final pairing = AndroidPairing(
        '127.0.0.1',
        client,
        port: pairingServer.port,
      );
      addTearDown(pairing.close);
      final server = servePairing(pairingServer);
      final identity = await pairing.run(() {
        expect(pairing.submit('invalid'), isFalse);
        final code =
            Iterable.generate(
              256,
              (byte) => '${byte.toRadixString(16).padLeft(2, '0')}1234',
            ).firstWhere(
              (code) =>
                  PairingProof.forCode(
                    code,
                    client.certificateDer,
                    tv.certificateDer,
                  ) !=
                  null,
            );
        expect(pairing.submit(code), isTrue);
      });
      await server;
      expect(identity.fingerprint, PairingProof.fingerprint(tv.certificateDer));

      final remoteServer = await listen();
      addTearDown(remoteServer.close);
      final remote = AndroidRemoteSession(
        '127.0.0.1',
        PairedIdentity.decode(identity.encode()),
        port: remoteServer.port,
      );
      addTearDown(remote.close);
      final commands = serveRemote(remoteServer);
      final lost = Completer<void>();
      await remote.connect(lost.complete);
      expect(remote.features, 615);
      final reading = remote.volume ?? await remote.volumes.first;
      expect(reading.volume, 40);
      expect(remote.supportsAbsoluteVolume, isTrue);
      expect(remote.content?.appId, 'com.example.tv');
      expect(reading.muted, isTrue);
      await remote.key(23);
      await remote.key(24);
      await remote.key(AndroidRemoteSession.channelUpKey);
      await remote.key(AndroidRemoteSession.channelDownKey);
      await remote.setVolume(60);
      await remote.setMuted(false);
      await remote.text('abc');
      await remote.submit();
      await remote.launchLink('vnd.youtube://');
      await commands;
      await lost.future.timeout(const Duration(seconds: 3));
    },
  );
  test('cancels on-screen pairing without submitting a secret', () async {
    final server = await listen();
    addTearDown(server.close);
    final pairing = AndroidPairing('127.0.0.1', client, port: server.port);
    addTearDown(pairing.close);
    final peer = servePairing(server, cancelBeforeProof: true);
    await expectLater(
      pairing.run(pairing.close),
      throwsA(
        isA<RemoteException>().having(
          (error) => error.code,
          'code',
          'cancelled',
        ),
      ),
    );
    await peer;
  });

  test(
    'rejects a remote socket whose certificate does not match the pin',
    () async {
      final server = await listen();
      addTearDown(server.close);
      final subscription = server.listen(
        (socket) => socket.destroy(),
        onError: (Object _) {},
      );
      addTearDown(subscription.cancel);
      final remote = AndroidRemoteSession(
        '127.0.0.1',
        PairedIdentity(client, PairingProof.fingerprint(client.certificateDer)),
        port: server.port,
      );
      addTearDown(remote.close);
      await expectLater(
        remote.connect(() {}),
        throwsA(
          isA<RemoteException>().having(
            (error) => error.code,
            'code',
            'certificate',
          ),
        ),
      );
    },
  );
}

Future<void> servePairing(
  SecureServerSocket server, {
  bool cancelBeforeProof = false,
}) async {
  final channel = FramedSocket(await server.first);
  try {
    for (final (request, reply) in [
      (10, 11),
      (20, 20),
      (30, 31),
      if (!cancelBeforeProof) (40, 41),
    ]) {
      final message = await channel.next();
      expect(message?[request], isA<List<int>>());
      channel.send({1: 2, 2: 200, reply: <int>[]});
    }
    await channel.socket.flush();
    await channel.next();
  } finally {
    channel.close();
  }
}

Future<void> serveRemote(SecureServerSocket server) async {
  final channel = FramedSocket(await server.first);
  try {
    channel.send({
      1: WireMessage.encode({1: 35 | 64 | 4 | 512}),
    });
    final configure = await channel.next();
    expect(WireMessage.decode(configure![1] as List<int>)[1], 615);
    channel.send({
      50: WireMessage.encode({1: 3, 4: 2, 6: 25, 7: 10, 8: 1}),
    });
    channel.send({
      20: WireMessage.encode({
        1: WireMessage.encode({1: 9, 2: 1, 6: 3, 12: 'com.example.tv'}),
        2: WireMessage.encode({1: 4, 3: 2, 4: 5}),
      }),
    });
    channel.send({2: <int>[]});
    final active = await channel.next();
    expect(WireMessage.decode(active![2] as List<int>)[1], 615);
    channel.send({
      8: WireMessage.encode({1: 42}),
    });
    final messages = [
      for (var index = 0; index < 10; index++) await channel.next(),
    ];
    final pong = messages.singleWhere(
      (message) => message?.containsKey(9) == true,
    );
    final keys = messages
        .where((message) => message?.containsKey(10) == true)
        .map((message) => WireMessage.decode(message![10] as List<int>));
    expect(WireMessage.decode(pong![9] as List<int>), {1: 42});
    expect(keys, [
      {1: 23, 2: 3},
      {1: 24, 2: 3},
      {1: 166, 2: 3},
      {1: 167, 2: 3},
    ]);
    List<Map<int, Object>> payloads(int field) => [
      for (final message in messages)
        if (message?[field] case final List<int> payload)
          WireMessage.decode(payload),
    ];
    expect(payloads(50), [
      {1: 3, 2: 15, 3: 1},
    ]);
    expect(payloads(51), [
      {1: 3, 2: 2},
    ]);
    expect(payloads(90).single[1], utf8.encode('vnd.youtube://'));
    final edits = payloads(21);
    expect(edits.map((edit) => (edit[1], edit[2])), [(9, 4), (9, 4)]);
    final replacement = WireMessage.decode(edits.first[3] as List<int>);
    expect(WireMessage.decode(replacement[2] as List<int>), {
      1: 2,
      2: 5,
      3: utf8.encode('abc'),
    });
    final submit = WireMessage.decode(edits.last[3] as List<int>);
    expect(WireMessage.decode(submit[5] as List<int>), {1: 3});
  } finally {
    channel.close();
  }
}
