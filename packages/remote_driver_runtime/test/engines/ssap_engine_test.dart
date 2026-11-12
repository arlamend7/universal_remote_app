import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';
import 'package:test/test.dart';

import '../support/test_ssap_manifest.dart';

import '../support/fake_transport.dart';
import '../support/standard_responses.dart';
import 'engine_test_context.dart';

OperationMapping _map(
  String operation,
  String kind, [
  Map<String, Object?>? p,
]) => OperationMapping(operation: operation, kind: kind, parameters: p ?? {});

void main() {
  final engine = SsapEngine();
  final connection = {
    'registration': testSsapManifest,
    'allowLegacyTransport': true,
  };
  RemoteDevice device({bool optIn = true}) => RemoteDevice(
    id: 'lg.webos:uuid:engine',
    name: 'TV',
    providerId: 'lg.webos',
    endpoints: [Uri.parse('ws://192.168.1.20:3000')],
    metadata: {if (optIn) 'allowInsecure': 'true'},
  );

  group('compile', () {
    test('accepts allow-listed SSAP calls and bounded templates', () {
      final operation = engine.compile(
        _map('set-volume', 'ssap.request', {
          'uri': 'ssap://audio/setVolume',
          'payload': {
            'volume': {r'$argument': 'volume'},
          },
        }),
      );
      expect(operation.describe()['uri'], 'ssap://audio/setVolume');
    });

    test(
      'rejects addresses, arguments and decoders outside the vocabulary',
      () {
        final invalid = [
          _map('volume-up', 'ssap.request', {'uri': 'https://evil.example/x'}),
          _map('volume-up', 'ssap.request', {'uri': 'ssap://evil.service/x'}),
          _map('volume-up', 'ssap.request', {
            'uri': 'ssap://audio/volumeUp',
            'payload': {
              'x': {r'$argument': 'password'},
            },
          }),
          _map('volume-up', 'ssap.request', {
            'uri': 'ssap://audio/volumeUp',
            'result': 'shell',
          }),
          _map('key-menu', 'ssap.pointer-button', {'button': 'menu; rm'}),
          _map('volume-up', 'ssap.request', {
            'uri': 'ssap://audio/volumeUp',
            'script': 'x',
          }),
        ];
        for (final mapping in invalid) {
          expect(() => engine.compile(mapping), throwsFormatException);
        }
      },
    );

    test('registration manifests cannot carry signatures or identities', () {
      expect(
        () => engine.compileConnection({
          'registration': {...testSsapManifest, 'signed': <String, Object?>{}},
        }),
        throwsFormatException,
      );
    });
  });

  group('session', () {
    late FakeTransport socket;
    late FakeTransport pointer;
    late EngineTestContext context;
    Future<EngineSession> open({RemoteDevice? target}) {
      final engine = SsapEngine(
        connector: (uri) async => uri.path == '/pointer' ? pointer : socket,
      );
      context = EngineTestContext(target ?? device(), connection: connection);
      return engine.open(context.build(engine));
    }

    setUp(() {
      socket = FakeTransport();
      pointer = FakeTransport();
      standardResponses(socket);
    });

    test('pairs, stores the key and executes typed requests', () async {
      final session = await open();
      addTearDown(session.close);
      expect(context.credentials.values['lg.webos:uuid:engine'], 'secret');
      expect(context.states, [DeviceConnectionState.pairing]);
      Future<Object?> run(
        String kind,
        Map<String, Object?> p, [
        Map<String, Object?> a = const {},
      ]) => session.execute(engine.compile(_map('set-volume', kind, p)), a);
      await run(
        'ssap.request',
        {
          'uri': 'ssap://audio/setVolume',
          'payload': {
            'volume': {r'$argument': 'volume'},
          },
        },
        {'volume': 25},
      );
      expect(socket.sent.last['payload'], {'volume': 25});
      final volume = await run('ssap.request', {
        'uri': 'ssap://audio/getVolume',
        'result': 'volume',
      });
      expect((volume! as VolumeState).volume, 30);
      final apps = await run('ssap.request', {
        'uri': 'ssap://com.webos.applicationManager/listApps',
        'result': 'applications',
      });
      expect((apps! as List).single, isA<DeviceApplication>());
      expect(session.facts['application.internal.service'], 'present');
      final software = await run('ssap.identify', {
        'uri': 'ssap://com.webos.service.update/getCurrentSWInformation',
        'osVersionPrefix': 'webOSTV ',
        'operatingSystem': 'webOS',
      });
      final info = software! as DeviceSoftwareInformation;
      expect(info.operatingSystemVersion, '5.0');
      expect(info.firmwareVersion, '04.50.56');
    });

    test('pointer frames use the authenticated host only', () async {
      final session = await open();
      addTearDown(session.close);
      await session.execute(
        engine.compile(
          _map('open-pointer', 'ssap.pointer-open', {
            'uri':
                'ssap://com.webos.service.networkinput/getPointerInputSocket',
          }),
        ),
        const {},
      );
      await session.execute(
        engine.compile(
          _map('key-menu', 'ssap.pointer-button', {'button': 'MENU'}),
        ),
        const {},
      );
      await session.execute(
        engine.compile(_map('pointer-move', 'ssap.pointer-move')),
        const {'dx': 3, 'dy': -4},
      );
      expect(pointer.frames, [
        'type:button\nname:MENU\n\n',
        'type:move\ndx:3\ndy:-4\ndown:0\n\n',
      ]);
    });

    test(
      'content readings derive inputs and live TV from declared data',
      () async {
        socket.respond = (request) {
          final uri = request['uri'];
          if (request['type'] == 'register') {
            socket.reply(request, {'client-key': 'k'}, type: 'registered');
            return;
          }
          socket.reply(request, switch (uri) {
            'ssap://com.webos.applicationManager/getForegroundAppInfo' => {
              'appId': 'com.webos.app.hdmi2',
            },
            _ => {'returnValue': true},
          });
        };
        final session = await open();
        addTearDown(session.close);
        final reading = await session.execute(
          engine.compile(
            _map('read-content', 'ssap.read-content', {
              'uri': 'ssap://com.webos.applicationManager/getForegroundAppInfo',
              'inputApplicationPrefix': 'com.webos.app.hdmi',
              'inputIdPrefix': 'HDMI_',
              'inputNamePrefix': 'HDMI ',
            }),
          ),
          const {},
        ) as ContentReading;
        expect(reading.input?.id, 'HDMI_2');
        expect(reading.input?.name, 'HDMI 2');
        expect(reading.content.isLiveTv, isFalse);
      },
    );

    test(
      'legacy transport needs both integration and user permission',
      () async {
        await expectLater(
          open(target: device(optIn: false)),
          throwsA(
            isA<RemoteException>().having((e) => e.code, 'code', 'insecure'),
          ),
        );
      },
    );

    test('a rejected saved key is deleted and reported as revoked', () async {
      final credentials = EngineTestContext(device()).credentials
        ..values['lg.webos:uuid:engine'] = 'stale';
      socket.respond = (request) => socket.reject(request, '403 revoked');
      final engine = SsapEngine(connector: (_) async => socket);
      final context = EngineTestContext(
        device(),
        connection: connection,
        credentials: credentials,
      );
      await expectLater(
        engine.open(context.build(engine)),
        throwsA(
          isA<RemoteException>().having((e) => e.code, 'code', 'revokedKey'),
        ),
      );
      expect(credentials.values, isEmpty);
    });
  });
}
