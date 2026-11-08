import 'dart:async';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_roku/src/roku_controller.dart';
import 'package:remote_roku/src/roku_ecp_client.dart';
import 'package:test/test.dart';

void main() {
  test('identifies a TV and routes only supported ECP commands', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final calls = <String>[];
    server.listen((request) {
      calls.add('${request.method} ${request.uri}');
      final body = switch (request.uri.path) {
        '/query/device-info' => '<device-info><serial-number>TEST01</serial-number><is-tv>true</is-tv></device-info>',
        '/query/apps' => '<apps><app id="12">Netflix &amp; more</app><app id="tvinput.hdmi1">HDMI 1</app></apps>',
        '/query/active-app' =>
          '<active-app><app id="12">Netflix</app></active-app>',
        _ => '',
      };
      if (request.uri.path == '/keypress/VolumeUp') {
        request.response.statusCode = 403;
      }
      request.response.write(body);
      unawaited(request.response.close());
    });
    final endpoint = Uri(scheme: 'http', host: '127.0.0.1', port: server.port);
    final device = RemoteDevice(
      id: 'profile',
      name: 'Roku',
      providerId: 'roku.ecp',
      endpoints: [endpoint],
    );
    final controller = RokuController(device, RokuEcpClient(endpoint));
    addTearDown(controller.dispose);
    await controller.connect();
    expect(controller.device.category, DeviceCategory.television);
    expect(controller.reportedDiscoveryIdentity, 'uuid:roku:ecp:TEST01');
    expect(controller.supports(RemoteCapability.absoluteVolume), isFalse);
    expect((await controller.applications()).single.name, 'Netflix & more');
    expect((await controller.currentContent()).appName, 'Netflix');
    await controller.press(NavigationKey.enter);
    await controller.togglePlayback();
    await controller.sendText('/');
    await controller.launchApplication('12');
    await controller.selectInput('tvinput.hdmi1');
    await expectLater(controller.volumeUp(), throwsA(isA<RemoteException>()));
    expect(controller.supports(RemoteCapability.volume), isFalse);
    expect(controller.supports(RemoteCapability.navigation), isTrue);
    expect(
      calls,
      containsAllInOrder([
        'POST /keypress/Select',
        'POST /keypress/Play',
        'POST /keypress/Lit_%2F',
        'POST /launch/12',
        'POST /keypress/InputHDMI1',
        'POST /keypress/VolumeUp',
      ]),
    );
  });
}
