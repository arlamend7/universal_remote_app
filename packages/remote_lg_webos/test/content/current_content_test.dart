import 'package:remote_core/remote_core.dart';
import 'package:remote_lg_webos/src/capabilities/content/lg_current_content_controller.dart';
import 'package:remote_lg_webos/src/capabilities/channels/lg_channel_controller.dart';
import 'package:remote_lg_webos/src/commands/services/lg_command_channel.dart';
import 'package:remote_lg_webos/remote_lg_webos.dart';
import 'package:test/test.dart';

import '../support/fake_transport.dart';

void main() {
  test('current app title comes from reported installed apps; live TV includes channel data', () async {
    final transport = FakeTransport();
    final client = SsapClient(transport);
    final unavailable = <RemoteCapability>[];
    final channel = LgCommandChannel(onUnavailable: unavailable.add)
      ..attach(client);
    var app = 'device.actual.app';
    transport.respond = (request) {
      final payload = switch (request['uri']) {
        'ssap://com.webos.applicationManager/getForegroundAppInfo' => {
          'appId': app,
        },
        'ssap://com.webos.applicationManager/listApps' => {
          'apps': [
            {'id': 'device.actual.app', 'title': 'Reported app'},
          ],
        },
        'ssap://tv/getCurrentChannel' => {
          'channelName': 'CBC',
          'channelNumber': '7.1',
        },
        _ => {'returnValue': true},
      };
      transport.reply(request, payload);
    };
    final content = LgCurrentContentController(channel);
    expect((await content.currentContent()).appName, 'Reported app');
    expect(
      transport.sent.any(
        (request) => request['uri'] == 'ssap://tv/getCurrentChannel',
      ),
      false,
    );
    app = 'com.webos.app.livetv';
    final live = await content.currentContent();
    expect(live.isLiveTv, true);
    expect(live.channelNumber, '7.1');
    expect(live.channelName, 'CBC');
    await LgChannelController(channel).channelUp();
    expect(transport.sent.last['uri'], 'ssap://tv/channelUp');
    await LgChannelController(channel).channelDown();
    expect(transport.sent.last['uri'], 'ssap://tv/channelDown');
    expect(unavailable, isEmpty);
    await client.close();
  });
  test('content permission failure does not revoke unrelated controls or invent channel data', () async {
    final transport = FakeTransport();
    final client = SsapClient(transport);
    final unavailable = <RemoteCapability>[];
    final channel = LgCommandChannel(onUnavailable: unavailable.add)
      ..attach(client);
    transport.respond = (request) =>
        transport.reject(request, '403 permission denied');
    await expectLater(
      LgCurrentContentController(channel).currentContent(),
      throwsA(isA<RemoteException>()),
    );
    expect(unavailable, isEmpty);
    await client.close();
  });
}
