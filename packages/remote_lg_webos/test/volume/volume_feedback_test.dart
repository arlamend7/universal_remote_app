import 'package:remote_core/remote_core.dart';
import 'package:remote_lg_webos/src/capabilities/volume/lg_volume_controller.dart';
import 'package:remote_lg_webos/src/commands/services/lg_command_channel.dart';
import 'package:remote_lg_webos/remote_lg_webos.dart';
import 'package:test/test.dart';

import '../support/fake_transport.dart';

void main() {
  for (final nested in [false, true]) {
    test(
      'volume feedback accepts ${nested ? 'nested' : 'flat'} levels with separate mute',
      () async {
        final transport = FakeTransport();
        final client = SsapClient(transport);
        final unavailable = <RemoteCapability>[];
        final channel = LgCommandChannel(onUnavailable: unavailable.add)
          ..attach(client);
        final volume = LgVolumeController(channel);
        transport.respond = (request) {
          final payload = request['uri'] == 'ssap://audio/getMute'
              ? <String, Object?>{'mute': true}
              : nested
              ? <String, Object?>{
                  'volumeStatus': {'volume': 35},
                }
              : <String, Object?>{'volume': 35};
          transport.reply(request, payload);
        };
        final state = await volume.readVolume();
        expect(state.volume, 35);
        expect(state.muted, true);
        expect(unavailable, isEmpty);
        expect(transport.sent.last['uri'], 'ssap://audio/getMute');
        await client.close();
      },
    );
  }

  test('top-level mute can accompany nested volume', () async {
    final transport = FakeTransport();
    final client = SsapClient(transport);
    final channel = LgCommandChannel(onUnavailable: (_) {})..attach(client);
    transport.respond = (request) => transport.reply(request, {
      'volumeStatus': {'volume': 12},
      'mute': false,
    });
    final state = await LgVolumeController(channel).readVolume();
    expect(state.volume, 12);
    expect(state.muted, false);
    expect(transport.sent, hasLength(1));
    await client.close();
  });

  test(
    'denied mute feedback preserves volume and adjustment commands',
    () async {
      final transport = FakeTransport();
      final client = SsapClient(transport);
      final unavailable = <RemoteCapability>[];
      final channel = LgCommandChannel(onUnavailable: unavailable.add)
        ..attach(client);
      final volume = LgVolumeController(channel);
      transport.respond = (request) {
        if (request['uri'] == 'ssap://audio/getMute') {
          transport.reject(request, '403 permission denied');
          return;
        }
        transport.reply(request, {'volume': 22});
      };
      final state = await volume.readVolume();
      expect(state.volume, 22);
      expect(state.muted, isNull);
      await volume.volumeUp();
      expect(transport.sent.last['uri'], 'ssap://audio/volumeUp');
      expect(unavailable, isEmpty);
      await client.close();
    },
  );

  test(
    'volume-only subscription updates use the separate mute query',
    () async {
      final transport = FakeTransport();
      final client = SsapClient(transport);
      final channel = LgCommandChannel(onUnavailable: (_) {})..attach(client);
      transport.respond = (request) => transport.reply(
        request,
        request['uri'] == 'ssap://audio/getMute'
            ? {'mute': false}
            : {'volume': 23},
      );
      final state = await LgVolumeController(channel).watchVolume().first;
      expect(state.volume, 23);
      expect(state.muted, false);
      await client.close();
    },
  );

  test('a denied volume write still revokes the control', () async {
    final transport = FakeTransport();
    final client = SsapClient(transport);
    final unavailable = <RemoteCapability>[];
    final channel = LgCommandChannel(onUnavailable: unavailable.add)
      ..attach(client);
    transport.respond = (request) =>
        transport.reject(request, '403 permission denied');
    await expectLater(
      LgVolumeController(channel).volumeUp(),
      throwsA(isA<RemoteException>()),
    );
    expect(unavailable, [RemoteCapability.volume]);
    await client.close();
  });
}
