import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';
import 'package:test/test.dart';

void main() {
  test('WebSocket round trip, state, close and send rejection', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final sockets = <WebSocket>[];
    final serverSubscription = server.listen((request) async {
      // Socket is retained and released in the test's finally block.
      // ignore: close_sinks
      final socket = await WebSocketTransformer.upgrade(request);
      sockets.add(socket);
      socket.listen((Object? message) => socket.add(message));
    });
    IoWebSocketTransport? transport;
    StreamSubscription<String>? messages;
    try {
      transport = await IoWebSocketTransport.connect(
        Uri.parse('ws://127.0.0.1:${server.port}'),
      );
      expect(transport.state, TransportState.open);
      final reply = Completer<String>();
      messages = transport.messages.listen(reply.complete);
      final closed = transport.states.first;
      transport.send('hello');
      expect(await reply.future, 'hello');
      await transport.close();
      expect(await closed, TransportState.closed);
      expect(() => transport!.send('closed'), throwsStateError);
      await transport.close();
    } finally {
      await messages?.cancel();
      await transport?.close();
      for (final socket in sockets) {
        await socket.close();
      }
      await serverSubscription.cancel();
      await server.close(force: true);
    }
  });
  test('cancellation aborts a stalled WebSocket handshake', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final seen = Completer<void>();
    final cancellation = StreamController<void>();
    final listener = server.listen((_) => seen.complete());
    try {
      final connecting = IoWebSocketTransport.connect(
        Uri.parse('ws://127.0.0.1:${server.port}'),
        timeout: const Duration(seconds: 20),
        cancellation: cancellation.stream,
      );
      final rejected = expectLater(
        connecting,
        throwsA(
          isA<RemoteException>().having((e) => e.code, 'code', 'cancelled'),
        ),
      );
      await seen.future.timeout(const Duration(seconds: 2));
      cancellation.add(null);
      await rejected.timeout(const Duration(seconds: 2));
    } finally {
      await cancellation.close();
      await listener.cancel();
      await server.close(force: true);
    }
  });

  test('TLS rejects unknown certificates and accepts only the configured exact pin', () async {
    final folder = await Directory.systemTemp.createTemp('remote-tls-');
    final certificate = '${folder.path}/certificate.pem';
    final key = '${folder.path}/key.pem';
    final generated = await Process.run('openssl', [
      'req',
      '-x509',
      '-newkey',
      'rsa:2048',
      '-nodes',
      '-keyout',
      key,
      '-out',
      certificate,
      '-days',
      '1',
      '-subj',
      '/CN=localhost',
    ]);
    expect(
      generated.exitCode,
      0,
      reason: 'Local TLS test certificate generation',
    );
    final context = SecurityContext()
      ..useCertificateChain(certificate)
      ..usePrivateKey(key);
    final server = await HttpServer.bindSecure(
      InternetAddress.loopbackIPv4,
      0,
      context,
    );
    final sockets = <WebSocket>[];
    final listener = server.listen((request) async {
      // Socket is released below.
      // ignore: close_sinks
      final socket = await WebSocketTransformer.upgrade(request);
      sockets.add(socket);
      socket.listen((Object? _) {});
    }, onError: (Object _) {});
    final uri = Uri.parse('wss://127.0.0.1:${server.port}');
    final pem = await File(certificate).readAsString();
    final pin = pem.replaceAll(RegExp(r'-----[^-]+-----|\s'), '');
    IoWebSocketTransport? transport;
    try {
      await expectLater(
        IoWebSocketTransport.connect(uri),
        throwsA(isA<HandshakeException>()),
      );
      await expectLater(
        IoWebSocketTransport.connect(
          uri,
          trustedCertificateDer: base64Encode([1, 2, 3]),
        ),
        throwsA(isA<HandshakeException>()),
      );
      final observed = await inspectPeerCertificate(uri);
      expect(observed.derBase64, pin);
      expect(observed.subject, contains('localhost'));
      expect(observed.fingerprint.split(':'), hasLength(20));
      // Inspection must not make a subsequent unpinned connection trusted.
      await expectLater(
        IoWebSocketTransport.connect(uri),
        throwsA(isA<HandshakeException>()),
      );
      transport = await IoWebSocketTransport.connect(
        uri,
        trustedCertificateDer: observed.derBase64,
      );
      final messages = transport.messages.listen((_) {});
      expect(transport.state, TransportState.open);
      await transport.close();
      await messages.cancel();
    } finally {
      await transport?.close();
      for (final socket in sockets) {
        await socket.close();
      }
      await listener.cancel();
      await server.close(force: true);
      await folder.delete(recursive: true);
    }
  });
  test('invalid endpoints and failed connections surface errors', () async {
    await expectLater(
      IoWebSocketTransport.connect(Uri.parse('https://localhost')),
      throwsArgumentError,
    );
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    await server.close();
    await expectLater(
      IoWebSocketTransport.connect(Uri.parse('ws://127.0.0.1:$port')),
      throwsA(isA<SocketException>()),
    );
  });
  test('a stalled handshake times out and cleans up', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final listener = server.listen((_) {});
    try {
      await expectLater(
        IoWebSocketTransport.connect(
          Uri.parse('ws://127.0.0.1:${server.port}'),
          timeout: const Duration(milliseconds: 40),
        ),
        throwsA(isA<TimeoutException>()),
      );
    } finally {
      await listener.cancel();
      await server.close(force: true);
    }
  });
  test('SSDP parses case-insensitive headers and stable USN', () {
    final item = SsdpAdvertisement.parse(
      utf8.encode(
        'HTTP/1.1 200 OK\r\nUSN: uuid:tv-id::service\r\nST: service\r\nLOCATION: http://192.168.1.5:3000/device.xml\r\n\r\n',
      ),
      InternetAddress('192.168.1.5'),
    );
    expect(item.identity, 'uuid:tv-id');
    expect(item.location!.host, '192.168.1.5');
  });
  test('malformed, missing and conflicting SSDP identities are rejected', () {
    for (final input in [
      'garbage',
      'HTTP/1.1 200 OK\r\nST: service\r\n\r\n',
      'HTTP/1.1 200 OK\r\nUSN: uuid:a\r\nUSN: uuid:b\r\nST: x\r\n\r\n',
      'HTTP/1.1 200 OK\r\nbroken\r\n\r\n',
    ]) {
      expect(
        () => SsdpAdvertisement.parse(
          utf8.encode(input),
          InternetAddress.loopbackIPv4,
        ),
        throwsFormatException,
      );
    }
  });
  test(
    'SSDP cancellation closes sockets without waiting for discovery window',
    () async {
      final cancelled = Completer<void>()..complete();
      final found = await const SsdpDiscovery(duration: Duration(seconds: 20))
          .search('urn:test', cancelled: cancelled.future)
          .timeout(const Duration(seconds: 2));
      expect(found, isEmpty);
    },
  );
  test('Wake-on-LAN has exact framing and rejects invalid MACs', () {
    final packet = wakePacket('02:11:22:33:44:55');
    expect(packet, hasLength(102));
    expect(packet.take(6), everyElement(255));
    expect(packet.skip(6).take(6), [2, 17, 34, 51, 68, 85]);
    expect(() => wakePacket('ff:ff:ff:ff:ff:ff'), throwsArgumentError);
    expect(() => wakePacket('invalid'), throwsArgumentError);
  });
}
