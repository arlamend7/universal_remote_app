import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:remote_android_tv/src/protocol/android_pairing.dart';
import 'package:remote_android_tv/src/protocol/android_remote_session.dart';
import 'package:remote_android_tv/src/protocol/framed_socket.dart';
import 'package:remote_android_tv/src/protocol/wire_message.dart';
import 'package:remote_android_tv/src/security/client_identity.dart';
import 'package:remote_android_tv/src/security/paired_identity.dart';
import 'package:remote_android_tv/src/security/pairing_proof.dart';
import 'package:test/test.dart';

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
      await remote.connect(() {});
      expect(remote.features, 35);
      await remote.key(23);
      await commands;
    },
  );
}

Future<void> servePairing(SecureServerSocket server) async {
  final channel = FramedSocket(await server.first);
  try {
    for (final (request, reply) in [(10, 11), (20, 20), (30, 31), (40, 41)]) {
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
      1: WireMessage.encode({1: 35 | 64}),
    });
    final configure = await channel.next();
    expect(WireMessage.decode(configure![1] as List<int>)[1], 35);
    channel.send({2: <int>[]});
    final active = await channel.next();
    expect(WireMessage.decode(active![2] as List<int>)[1], 35);
    channel.send({
      8: WireMessage.encode({1: 42}),
    });
    final messages = [await channel.next(), await channel.next()];
    final pong = messages.firstWhere(
      (message) => message?.containsKey(9) == true,
    );
    final key = messages.firstWhere(
      (message) => message?.containsKey(10) == true,
    );
    expect(WireMessage.decode(pong![9] as List<int>), {1: 42});
    expect(WireMessage.decode(key![10] as List<int>), {1: 23, 2: 3});
  } finally {
    channel.close();
  }
}
