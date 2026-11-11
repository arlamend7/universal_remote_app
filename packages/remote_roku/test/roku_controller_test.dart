import 'dart:async';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_roku/src/roku_controller.dart';
import 'package:remote_driver_runtime/roku_ecp.dart';
import 'package:test/test.dart';

void main() {
  test('identifies a TV and routes only supported ECP commands', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final calls = <String>[];
    var activeApp = '<app id="12">Netflix</app>';
    server.listen((request) {
      calls.add('${request.method} ${request.uri}');
      final body = switch (request.uri.path) {
        '/query/device-info' => '<device-info><serial-number>TEST01</serial-number><is-tv>true</is-tv></device-info>',
        '/query/apps' => '<apps><app id="12">Netflix &amp; more</app><app id="tvinput.hdmi1">HDMI 1</app></apps>',
        '/query/tv-channels' => '<tv-channels><channel><number>7.1</number><name>Local</name></channel></tv-channels>',
        '/query/tv-active-channel' => '<tv-channel><channel><active-input>true</active-input><number>7.1</number><program-title>News</program-title></channel></tv-channel>',
        '/query/active-app' => '<active-app>$activeApp</active-app>',
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
    final controller = RokuController(
      device,
      RokuEcpClient(endpoint),
      bindings: DriverBindings({
        'volume-up': 'VolumeUp',
        'volume-down': 'PowerOff',
      }),
    );
    addTearDown(controller.dispose);
    await controller.connect();
    expect(controller.device.category, DeviceCategory.television);
    expect(controller.reportedDiscoveryIdentity, 'uuid:roku:ecp:TEST01');
    expect(controller.supports(RemoteCapability.absoluteVolume), isFalse);
    expect((await controller.applications()).single.name, 'Netflix & more');
    final activity = await controller.currentContent();
    expect(activity.channelNumber, '7.1');
    expect(activity.programTitle, 'News');
    expect(controller.supports(RemoteCapability.currentInput), isTrue);
    expect(controller.currentInput, isNull);
    final changes = <DeviceInput?>[];
    final subscription = controller.currentInputChanges.listen(changes.add);
    addTearDown(subscription.cancel);
    activeApp = '<app id="tvinput.hdmi1">HDMI 1</app>';
    await controller.currentContent();
    expect(controller.currentInput?.id, 'tvinput.hdmi1');
    activeApp = '<app id="12">Netflix</app>';
    await controller.currentContent();
    expect(controller.currentInput, isNull);
    expect(changes.map((input) => input?.name), ['HDMI 1', null]);
    expect((await controller.channels()).single.number, '7.1');
    expect(
      (await controller.applications()).single.artwork?.path,
      '/query/icon/12',
    );
    await controller.channelUp();
    await controller.sendMedia(MediaAction.rewind);
    await controller.sendKey(RemoteKey.mute);
    await controller.press(NavigationKey.enter);
    await controller.togglePlayback();
    await controller.sendText('/');
    await controller.launchApplication('12');
    await controller.selectInput('tvinput.hdmi1');
    final changed = controller.capabilityChanges.first;
    await expectLater(controller.volumeUp(), throwsA(isA<RemoteException>()));
    await changed;
    expect(controller.supports(RemoteCapability.volume), isFalse);
    expect(controller.supports(RemoteCapability.navigation), isTrue);
    expect(
      calls,
      containsAllInOrder([
        'POST /keypress/ChannelUp',
        'POST /keypress/Rev',
        'POST /keypress/VolumeMute',
        'POST /keypress/Select',
        'POST /keypress/Play',
        'POST /keypress/Lit_%2F',
        'POST /launch/12',
        'POST /keypress/InputHDMI1',
        'POST /keypress/VolumeUp',
      ]),
    );
  });
  test(
    'streaming player without a catalog exposes only its supported keys',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        request.response.write(switch (request.uri.path) {
          '/query/device-info' => '<device-info><serial-number>PLAYER</serial-number><is-tv>false</is-tv><supports-audio-volume-control>true</supports-audio-volume-control><supports-tv-power-control>false</supports-tv-power-control></device-info>',
          '/query/apps' => '<apps/>',
          _ => '<active-app/>',
        });
        await request.response.close();
      });
      final endpoint = Uri(
        scheme: 'http',
        host: '127.0.0.1',
        port: server.port,
      );
      final controller = RokuController(
        RemoteDevice(
          id: 'player',
          name: 'Roku',
          providerId: 'roku.ecp',
          endpoints: [endpoint],
        ),
        RokuEcpClient(endpoint),
      );
      addTearDown(controller.dispose);
      await controller.connect();
      expect(controller.device.category, DeviceCategory.mediaPlayer);
      expect(resolvedCapabilities(controller), {
        RemoteCapability.navigation,
        RemoteCapability.textInput,
        RemoteCapability.playbackToggle,
        RemoteCapability.playbackScan,
        RemoteCapability.instantReplay,
        RemoteCapability.mute,
        RemoteCapability.volume,
      });
      await expectLater(
        controller.sendMedia(MediaAction.play),
        throwsA(isA<RemoteException>()),
      );
    },
  );
}
