import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';
import 'package:remote_network/remote_network.dart';
import 'package:test/test.dart';

import 'driver_runtime_test.dart' show manifest;
import 'memory_driver_credentials.dart';

DriverExchange _exchange(String operation, String type) => DriverExchange.parse(
  jsonEncode({
    'operation': 'websocket.$operation',
    'payload': {'type': type},
  }),
  manifest,
);

Future<DriverConnection> _connection(
  void Function(WebSocket socket, Map<String, Object?> message) onRequest,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  addTearDown(() => server.close(force: true));
  final listener = server.listen((request) async {
    // The runtime closes its connection after use.
    // ignore: close_sinks
    final socket = await WebSocketTransformer.upgrade(request);
    socket.listen((message) {
      onRequest(socket, jsonDecode(message as String) as Map<String, Object?>);
    });
  });
  addTearDown(listener.cancel);
  return DriverRuntime(
    connect:
        (_, {required cancellation, required timeout, trustedCertificateDer}) =>
            IoWebSocketTransport.connect(
              Uri(scheme: 'ws', host: '127.0.0.1', port: server.port),
              cancellation: cancellation,
              timeout: timeout,
            ),
  ).connection(endpoint: Uri.parse('wss://192.168.1.2:9000/remote'));
}

void main() {
  test(
    'pairs, authenticates after reconnect and receives subscribed feedback',
    () async {
      final connection = await _connection((socket, message) {
        final type = message['type'];
        socket.add(
          jsonEncode({
            'id': message['id'],
            'ok': switch (type) {
              'pair' => message['code'] == '1234',
              'auth' => message['token'] == 'fictional-token',
              _ => true,
            },
            if (type == 'pair') 'token': 'fictional-token',
          }),
        );
        if (type == 'subscribe' || type == 'unsubscribe') {
          socket.add('{"event":"volume","value":25}');
        }
      });
      addTearDown(connection.close);
      final credentials = MemoryDriverCredentials();
      final selected = DriverCredentialScope(
        credentials,
        'example.tv',
        'tv-one',
      );
      final other = DriverCredentialScope(credentials, 'example.tv', 'tv-two');
      final feedback = <Map<String, Object?>>[];
      connection.onFeedback = feedback.add;

      await connection.connect();
      await connection.pair(
        _exchange('pair', 'pair'),
        selected,
        requestCode: () async => '1234',
      );
      expect(await other.read(), isNull);
      await connection.close();
      await connection.connect();
      await connection.authenticate(
        _exchange('authenticate', 'auth'),
        selected,
      );
      await connection.request(_exchange('subscribe', 'subscribe'));
      await connection.request(_exchange('unsubscribe', 'unsubscribe'));
      expect(feedback, [
        {'event': 'volume', 'value': 25},
      ]);
    },
  );

  test('bad response, timeout and cancellation permit reconnect', () async {
    final seen = Completer<void>();
    final connection = await _connection((socket, message) {
      if (message['type'] == 'cancel') {
        seen.complete();
      }
      if (message['type'] == 'mismatch') {
        socket.add('{"id":-1,"ok":true}');
      }
    });
    addTearDown(connection.close);

    await connection.connect();
    await expectLater(
      connection.request(_exchange('request', 'mismatch')),
      _error('driverResponse'),
    );
    await connection.connect();
    await expectLater(
      connection.request(
        _exchange('request', 'timeout'),
        timeout: const Duration(milliseconds: 50),
      ),
      _error('driverTimeout'),
    );
    await connection.connect();
    final cancellation = StreamController<void>();
    addTearDown(cancellation.close);
    final result = expectLater(
      connection.request(
        _exchange('request', 'cancel'),
        cancellation: cancellation.stream,
      ),
      _error('cancelled'),
    );
    await seen.future.timeout(const Duration(seconds: 2));
    cancellation.add(null);
    await result;
    await connection.connect();
  });

  test('driver files cannot select credential fields or storage keys', () {
    for (final field in ['token', 'code', 'id']) {
      expect(
        () => DriverExchange.parse(
          '{"operation":"websocket.authenticate","payload":{"$field":"bad"}}',
          manifest,
        ),
        throwsFormatException,
      );
    }
  });
}

Matcher _error(String code) =>
    throwsA(isA<RemoteException>().having((error) => error.code, 'code', code));
