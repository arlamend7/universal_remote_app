import 'package:remote_core/remote_core.dart';

import 'support/lg_fixture_api.dart';

import 'package:remote_driver_runtime/src/adapters/lg_webos/capabilities/applications/lg_application_controller.dart';
import 'package:remote_driver_runtime/src/adapters/lg_webos/commands/services/lg_command_channel.dart';
import 'package:test/test.dart';

import 'support/fake_transport.dart';

void main() {
  late FakeTransport transport;
  late SsapClient client;
  late LgApplicationController apps;

  setUp(() {
    transport = FakeTransport();
    client = SsapClient(transport);
    transport.respond = (request) =>
        transport.reply(request, {'returnValue': true});
    apps = LgApplicationController(
      LgCommandChannel(onUnavailable: (_) {})..attach(client),
    );
  });
  tearDown(() => client.close());

  test('launches by id and passes a content id', () async {
    await apps.launch('netflix');
    expect(transport.sent.last['uri'], 'ssap://system.launcher/launch');
    expect(transport.sent.last['payload'], {'id': 'netflix'});
    await apps.launch('youtube.leanback.v4?contentId=abc123');
    expect(transport.sent.last['payload'], {
      'id': 'youtube.leanback.v4',
      'contentId': 'abc123',
    });
  });

  test('opens web addresses through the launcher', () async {
    await apps.launch('https://example.com/watch?v=1');
    expect(transport.sent.last['uri'], 'ssap://system.launcher/open');
    expect(transport.sent.last['payload'], {
      'target': 'https://example.com/watch?v=1',
    });
  });

  test('rejects malformed links without sending', () async {
    final before = transport.sent.length;
    for (final bad in [
      'app?x=1',
      'app?contentId=',
      '?contentId=1',
      'http://',
    ]) {
      await expectLater(apps.launch(bad), throwsA(isA<RemoteException>()));
    }
    expect(transport.sent.length, before);
  });

  test('screen power commands use the TV power service', () async {
    final channel = LgCommandChannel(onUnavailable: (_) {})..attach(client);
    await channel.send(
      RemoteCapability.screenPower,
      'com.webos.service.tvpower/power/turnOffScreen',
    );
    expect(
      transport.sent.last['uri'],
      'ssap://com.webos.service.tvpower/power/turnOffScreen',
    );
  });
}
