import 'dart:async';
import 'dart:convert';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';
import 'package:test/test.dart';

import '../support/fake_transport.dart';
import 'engine_test_context.dart';

void main() {
  const connection = {
    'pairing': {
      'message': {'type': 'pair'},
    },
    'authentication': {
      'message': {'type': 'hello'},
    },
  };
  final device = RemoteDevice(
    id: 'example:profile',
    name: 'Example',
    providerId: 'example.smarttv',
    endpoints: [Uri.parse('wss://192.168.1.50:7443/remote')],
  );

  test('reserved envelope fields cannot be declared', () {
    final engine = JsonWebSocketEngine();
    expect(
      () => engine.compile(
        OperationMapping(
          operation: 'volume-up',
          kind: 'json-websocket.request',
          parameters: const {
            'message': {'type': 'x', 'token': 'steal'},
          },
        ),
      ),
      throwsFormatException,
    );
  });

  test('pairs with a code, authenticates and decodes replies', () async {
    final socket = FakeTransport();
    socket.respond = (request) {
      final reply = <String, Object?>{'id': request['id'], 'ok': true};
      if (request['type'] == 'pair') {
        reply['token'] = 'issued';
      }
      if (request['type'] == 'getVolume') {
        reply['volume'] = 12;
        reply['muted'] = false;
      }
      scheduleMicrotask(() => socket.incoming.add(jsonEncode(reply)));
    };
    final engine = JsonWebSocketEngine(connector: (_) async => socket);
    final context = EngineTestContext(device, connection: connection);
    final opening = engine.open(context.build(engine));
    await Future<void>.delayed(Duration.zero);
    expect(await context.submit!('bad code!'), isFalse);
    expect(await context.submit!('1234'), isTrue);
    final session = await opening;
    addTearDown(session.close);
    expect(context.credentials.values['example:profile'], 'issued');
    expect(socket.sent.map((message) => message['type']), ['pair', 'hello']);
    expect(socket.sent.last['token'], 'issued');
    final volume = await session.execute(
      engine.compile(
        OperationMapping(
          operation: 'read-volume',
          kind: 'json-websocket.request',
          parameters: const {
            'message': {'type': 'getVolume'},
            'result': 'volume',
          },
        ),
      ),
      const {},
    );
    expect((volume! as VolumeState).volume, 12);
  });
}
