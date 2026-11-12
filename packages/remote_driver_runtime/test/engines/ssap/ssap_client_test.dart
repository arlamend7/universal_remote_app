import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/ssap.dart';
import 'package:test/test.dart';

import 'package:remote_driver_runtime/src/engines/ssap/pointer/pointer_button_frame.dart';

import '../../support/fake_transport.dart';
import '../../support/test_ssap_manifest.dart';

void main() {
  test(
    'registration waits for registered event and requests prompt permissions',
    () async {
      final transport = FakeTransport();
      final client = SsapClient(transport);
      transport.respond = (request) {
        transport.reply(request, {'pairingType': 'PROMPT'});
        scheduleMicrotask(
          () => transport.reply(request, {
            'client-key': 'private',
          }, type: 'registered'),
        );
      };
      try {
        expect(await client.register(manifest: testSsapManifest), 'private');
        final payload =
            transport.sent.single['payload'] as Map<String, dynamic>;
        expect(payload['pairingType'], 'PROMPT');
        expect(payload.containsKey('client-key'), isFalse);
        final manifest = payload['manifest'] as Map<String, dynamic>;
        expect(manifest.containsKey('signatures'), isFalse);
        expect(manifest['permissions'], contains('CONTROL_AUDIO'));
      } finally {
        await client.close();
      }
    },
  );
  test(
    'saved key reused; pairing rejection is typed without leaking payload',
    () async {
      final transport = FakeTransport();
      final client = SsapClient(transport);
      transport.respond = (request) =>
          transport.reject(request, '403 rejected secret-token');
      try {
        await expectLater(
          client.register(clientKey: 'saved', manifest: testSsapManifest),
          throwsA(
            isA<RemoteException>()
                .having((e) => e.code, 'code', 'pairingRejected')
                .having(
                  (e) => e.message,
                  'message',
                  isNot(contains('secret-token')),
                ),
          ),
        );
        expect(
          (transport.sent.single['payload']
              as Map<String, dynamic>)['client-key'],
          'saved',
        );
      } finally {
        await client.close();
      }
    },
  );
  test('concurrent request IDs correlate out-of-order responses', () async {
    final transport = FakeTransport();
    final client = SsapClient(transport);
    try {
      final one = client.request('audio/one');
      final two = client.request('audio/two');
      expect(transport.sent[0]['id'], isNot(transport.sent[1]['id']));
      transport.reply(transport.sent[1], {'value': 2});
      transport.reply(transport.sent[0], {'value': 1});
      expect((await one)['value'], 1);
      expect((await two)['value'], 2);
    } finally {
      await client.close();
    }
  });
  test('commands and registration have bounded timeouts', () async {
    final client = SsapClient(
      FakeTransport(),
      requestTimeout: const Duration(milliseconds: 15),
    );
    try {
      await expectLater(
        client.request('audio/getVolume'),
        throwsA(
          isA<RemoteException>().having((e) => e.code, 'code', 'timeout'),
        ),
      );
      await expectLater(
        client.register(
          manifest: testSsapManifest,
          timeout: const Duration(milliseconds: 15),
        ),
        throwsA(
          isA<RemoteException>().having(
            (e) => e.code,
            'code',
            'pairingTimeout',
          ),
        ),
      );
    } finally {
      await client.close();
    }
  });
  test('error response fails only matching request', () async {
    final transport = FakeTransport();
    final client = SsapClient(transport);
    try {
      final failed = client.request('bad');
      final good = client.request('good');
      final assertion = expectLater(
        failed,
        throwsA(
          isA<RemoteException>().having((e) => e.code, 'code', 'unsupported'),
        ),
      );
      transport.reject(transport.sent[0], '404 not found');
      transport.reply(transport.sent[1], {'ok': true});
      await assertion;
      expect((await good)['ok'], true);
    } finally {
      await client.close();
    }
  });
  test('subscriptions continue after first response and unsubscribe on cancellation', () async {
    final transport = FakeTransport();
    final client = SsapClient(transport);
    final values = <Map<String, Object?>>[];
    final subscription = client.subscribe('audio/getVolume').listen(values.add);
    await Future<void>.delayed(Duration.zero);
    final request = transport.sent.single;
    transport.reply(request, {'volume': 1});
    transport.reply(request, {'volume': 2});
    await Future<void>.delayed(Duration.zero);
    expect(values.map((e) => e['volume']), [1, 2]);
    await subscription.cancel();
    expect(transport.sent.last['type'], 'unsubscribe');
    await client.close();
  });
  test(
    'unexpected disconnect and malformed JSON fail pending requests',
    () async {
      for (final malformed in [false, true]) {
        final transport = FakeTransport();
        final client = SsapClient(transport);
        final pending = client.request('audio/getVolume');
        final assertion = expectLater(pending, throwsA(isA<RemoteException>()));
        if (malformed) {
          transport.incoming.add('not json');
        } else {
          await transport.close();
        }
        await assertion;
        await client.close();
      }
    },
  );
  test('oversized SSAP responses terminate the session', () async {
    final transport = FakeTransport();
    final client = SsapClient(transport);
    addTearDown(client.close);
    final pending = client.request('audio/getVolume');
    final assertion = expectLater(
      pending,
      throwsA(
        isA<RemoteException>().having(
          (error) => error.code,
          'code',
          'protocol',
        ),
      ),
    );
    transport.incoming.add(' ' * (2 * 1024 * 1024 + 1));
    await assertion;
    expect(client.isClosed, isTrue);
  });

  test('pointer navigation uses blank-line separators and click for OK', () {
    expect(pointerButtonFrame('UP'), 'type:button\nname:UP\n\n');
    expect(pointerButtonFrame('ENTER'), 'type:button\nname:ENTER\n\n');
    for (final key in NavigationKey.values) {
      expect(
        pointerButtonFrame(key.name.toUpperCase()).endsWith('\n\n'),
        isTrue,
      );
    }
  });
}
