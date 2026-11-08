// SDK-only deterministic checks; failures produce a nonzero process exit.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_lg_webos/remote_lg_webos.dart';
import 'package:remote_network/remote_network.dart';

void check(bool condition, String description) {
  if (!condition) throw StateError(description);
  stdout.writeln('PASS: $description');
}

void rejects(void Function() action, String description) {
  try {
    action();
  } on ArgumentError {
    check(true, description);
    return;
  } on StateError {
    check(true, description);
    return;
  } on FormatException {
    check(true, description);
    return;
  }
  throw StateError(description);
}

Future<void> main() async {
  final capabilities = {RemoteCapability.volume};
  final device = RemoteDevice(id: 'tv', name: 'TV', capabilities: capabilities);
  capabilities.clear();
  check(device.supports(RemoteCapability.volume), 'Capabilities are copied');
  check(
    !device.supports(RemoteCapability.power),
    'Unsupported capability is absent',
  );
  rejects(
    () => RemoteDevice(id: '', name: 'TV', capabilities: {}),
    'Empty ID rejected',
  );
  rejects(() => lgWebOsEndpoint('http://192.168.1.10'), 'URL input rejected');
  rejects(() => lgWebOsEndpoint('127.0.0.1'), 'Loopback TV rejected');
  check(
    lgWebOsEndpoint('192.168.1.10', secure: false).port == 3000,
    'Standard LG endpoint',
  );
  check(
    lgWebOsEndpoint('192.168.1.10', secure: true).scheme == 'wss',
    'Secure LG endpoint',
  );
  final request = SsapRequest(id: '1', uri: Uri.parse('ssap://audio/volumeUp'));
  final decoded = jsonDecode(request.encode()) as Map<String, dynamic>;
  check(
    decoded['type'] == 'request' &&
        decoded['id'] == '1' &&
        decoded['uri'] == 'ssap://audio/volumeUp',
    'SSAP request serialization',
  );
  rejects(
    () => SsapRequest(id: '', uri: Uri.parse('ssap://audio/volumeUp')),
    'Invalid SSAP request rejected',
  );

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final serverTask = () async {
    final request = await server.first;
    final socket = await WebSocketTransformer.upgrade(request);
    try {
      await for (final message in socket) {
        socket.add(message);
      }
    } finally {
      await socket.close();
    }
  }();
  IoWebSocketTransport? transport;
  try {
    transport = await IoWebSocketTransport.connect(
      Uri.parse('ws://127.0.0.1:${server.port}'),
    );
    final reply = Completer<String>();
    final subscription = transport.messages.listen((message) {
      if (!reply.isCompleted) reply.complete(message);
    });
    transport.send('hello');
    check(
      await reply.future.timeout(const Duration(seconds: 2)) == 'hello',
      'SDK WebSocket loopback round trip',
    );
    await transport.close();
    await serverTask.timeout(const Duration(seconds: 3));
    rejects(() => transport!.send('closed'), 'Sending after close rejected');
    await subscription.cancel();
  } finally {
    await transport?.close();
    await server.close(force: true);
  }
  stdout.writeln('All smoke checks passed.');
}
