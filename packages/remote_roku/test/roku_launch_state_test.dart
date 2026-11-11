import 'dart:async';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_roku/src/roku_controller.dart';
import 'package:remote_roku/src/roku_ecp_client.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late RokuController controller;
  final calls = <String>[];
  var player = '<player error="false" state="play"/>';

  setUp(() async {
    calls.clear();
    player = '<player error="false" state="play"/>';
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      calls.add('${request.method} ${request.uri}');
      final body = switch (request.uri.path) {
        '/query/device-info' =>
          '<device-info><serial-number>TEST01</serial-number><is-tv>true</is-tv>'
              '<model-name>Roku Test</model-name>'
              '<software-version>14.1.0</software-version>'
              '<software-build>09021</software-build></device-info>',
        '/query/apps' => '<apps><app id="12">Netflix</app></apps>',
        '/query/active-app' =>
          '<active-app><app id="12">Netflix</app></active-app>',
        '/query/media-player' => player,
        _ => '',
      };
      request.response.write(body);
      unawaited(request.response.close());
    });
    final endpoint = Uri(scheme: 'http', host: '127.0.0.1', port: server.port);
    controller = RokuController(
      RemoteDevice(
        id: 'profile',
        name: 'Roku',
        providerId: 'roku.ecp',
        endpoints: [endpoint],
      ),
      RokuEcpClient(endpoint),
    );
    await controller.connect();
  });

  tearDown(() async {
    await controller.dispose();
    await server.close(force: true);
  });

  test('the model and software version come from device-info', () {
    expect(controller.device.model, 'Roku Test');
    expect(controller.device.metadata['softwareVersion'], '14.1.0');
    final software = controller.device.softwareInformation!;
    expect(software.source, DeviceInformationSource.protocolResponse);
    expect(software.operatingSystemVersion, '14.1.0');
    expect(software.buildNumber, '09021');
    expect(software.firmwareVersion, isNull);
  });

  test('playback state reports only what the player says', () async {
    expect(await controller.playbackState(), isTrue);
    player = '<player error="false" state="pause"/>';
    expect(await controller.playbackState(), isFalse);
    player = '<player error="false" state="buffer"/>';
    expect(await controller.playbackState(), isNull);
    player = '';
    expect(await controller.playbackState(), isNull);
  });

  test('a deep link launches an installed app with its content id', () async {
    await controller.launchApplication('12?contentId=abc123&mediaType=movie');
    expect(calls.last, 'POST /launch/12?contentId=abc123&mediaType=movie');
    await controller.launchApplication('12');
    expect(calls.last, 'POST /launch/12');
  });

  test('malformed or unknown deep links are rejected', () async {
    for (final target in [
      '12?mediaType=movie',
      '12?contentId=x&mediaType=bogus',
      '12?contentId=x&other=1',
      '99?contentId=x',
      '?contentId=x',
    ]) {
      await expectLater(
        controller.launchApplication(target),
        throwsA(isA<RemoteException>()),
        reason: target,
      );
    }
  });
}
