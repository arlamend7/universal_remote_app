import 'package:test/test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_lg_webos/remote_lg_webos.dart';
import 'package:remote_lg_webos/src/commands/services/lg_command_channel.dart';
import 'package:remote_lg_webos/src/capabilities/applications/lg_application_controller.dart';
import 'package:remote_lg_webos/src/capabilities/text/lg_text_controller.dart';
import 'package:remote_lg_webos/src/capabilities/channels/lg_channel_selection_controller.dart';
import 'package:remote_lg_webos/src/pointer/services/lg_pointer_connection.dart';

import 'support/fake_transport.dart';

void main() {
  test('sound settings require an advertised app and failures stay capability-scoped', () async {
    final transport = FakeTransport();
    final client = SsapClient(transport);
    addTearDown(client.close);
    final unavailable = <RemoteCapability>[];
    final channel = LgCommandChannel(onUnavailable: unavailable.add)
      ..attach(client);
    final apps = LgApplicationController(channel);
    await expectLater(
      apps.openAccessorySettings(),
      throwsA(isA<RemoteException>()),
    );
    transport.respond = (request) => transport.reply(request, {
      'apps': [
        {'id': 'com.palm.app.settings', 'title': 'Settings', 'visible': false},
      ],
    });
    expect(await apps.applications(), isEmpty);
    expect(apps.hasSettings, isTrue);
    transport.respond = (request) =>
        transport.reply(request, {'returnValue': true});
    await apps.openAccessorySettings();
    expect(transport.sent.last['uri'], 'ssap://system.launcher/launch');
    expect(transport.sent.last['payload'], {
      'id': 'com.palm.app.settings',
      'params': {'target': 'sound'},
    });
    transport.respond = (request) =>
        transport.reject(request, '403 permission denied');
    await expectLater(
      apps.openAccessorySettings(),
      throwsA(isA<RemoteException>()),
    );
    expect(unavailable, [RemoteCapability.accessorySettings]);
  });

  test(
    'media and text commands use typed, correlated protocol requests',
    () async {
      final transport = FakeTransport();
      final client = SsapClient(transport);
      final channel = LgCommandChannel(onUnavailable: (_) {})..attach(client);
      transport.respond = (request) =>
          transport.reply(request, {'returnValue': true});
      for (final action in MediaAction.values) {
        await channel.send(
          RemoteCapability.media,
          'media.controls/${action.name}',
        );
        expect(
          transport.sent.last['uri'],
          'ssap://media.controls/${action.name}',
        );
      }
      final text = LgTextController(channel);
      await text.sendText('User-entered text');
      expect(
        transport.sent.last['uri'],
        'ssap://com.webos.service.ime/insertText',
      );
      expect(transport.sent.last['payload'], {
        'text': 'User-entered text',
        'replace': 0,
      });
      await text.enter();
      expect(
        transport.sent.last['uri'],
        'ssap://com.webos.service.ime/sendEnterKey',
      );
      await expectLater(text.sendText(''), throwsArgumentError);
      await client.close();
    },
  );
  test('channel shortcuts retain the TV reported ID and permission rejection is capability-scoped', () async {
    final transport = FakeTransport();
    final client = SsapClient(transport);
    final unavailable = <RemoteCapability>[];
    final channel = LgCommandChannel(onUnavailable: unavailable.add)
      ..attach(client);
    transport.respond = (request) => transport.reply(request, {
      'channelList': [
        {
          'channelId': 'actual-channel-id',
          'channelName': 'CBC',
          'channelNumber': '7.1',
        },
      ],
    });
    final selection = LgChannelSelectionController(channel);
    final choices = await selection.channels();
    expect(choices.single.id, 'actual-channel-id');
    await selection.selectChannel(choices.single.id);
    expect(transport.sent.last['payload'], {'channelId': 'actual-channel-id'});
    transport.respond = (request) =>
        transport.reject(request, '403 permission denied');
    await expectLater(
      selection.selectChannel('actual-channel-id'),
      throwsA(isA<RemoteException>()),
    );
    expect(unavailable, [RemoteCapability.channelSelection]);
    await client.close();
  });
  test('pointer movement, scroll, click and keypad frames are delimited and validated', () async {
    final transport = FakeTransport();
    final pointer = LgPointerConnection(
      connector: (_) async => transport,
      onUnavailable: () {},
    );
    await pointer.open(
      'ws://127.0.0.1:3000/pointer',
      Uri.parse('ws://127.0.0.1:3000'),
      const LgConnectionOptions(allowInsecure: true),
    );
    pointer.motion('move', 12, -5);
    pointer.motion('scroll', 0, 2);
    pointer.click();
    pointer.specialKey(RemoteKey.digit7);
    expect(transport.frames[0], contains('type:move\ndx:12\ndy:-5'));
    expect(transport.frames[1], contains('type:scroll'));
    expect(transport.frames[2], 'type:click\n\n');
    expect(transport.frames[3], 'type:button\nname:7\n\n');
    expect(transport.frames.every((frame) => frame.endsWith('\n\n')), true);
    expect(() => pointer.motion('move', double.nan, 0), throwsArgumentError);
    await pointer.close();
  });
}
