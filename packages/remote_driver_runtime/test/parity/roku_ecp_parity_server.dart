import 'dart:async';
import 'dart:io';

import 'support/parity_recorder.dart';

/// A loopback ECP endpoint that answers every documented query.
final class RokuEcpParityServer {
  RokuEcpParityServer(this.recorder);

  final ParityRecorder recorder;
  HttpServer? _server;

  Uri get endpoint =>
      Uri(scheme: 'http', host: '127.0.0.1', port: _server!.port);

  Future<void> start() async {
    final server = _server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    server.listen(_answer);
  }

  Future<void> close() async => _server?.close(force: true);

  void _answer(HttpRequest request) {
    recorder.add({'ecp': '${request.method} ${request.uri}'});
    request.response.write(_body(request.uri.path));
    unawaited(request.response.close());
  }

  String _body(String path) => switch (path) {
    '/query/device-info' =>
      '<device-info><serial-number>PARITY01</serial-number>'
          '<vendor-name>Roku</vendor-name><model-name>Parity TV</model-name>'
          '<model-number>7000X</model-number>'
          '<software-version>12.5.0</software-version>'
          '<software-build>4178</software-build><is-tv>true</is-tv>'
          '<supports-tv-power-control>true</supports-tv-power-control>'
          '</device-info>',
    '/query/apps' =>
      '<apps><app id="12">Netflix</app>'
          '<app id="tvinput.hdmi1">HDMI 1</app></apps>',
    '/query/tv-channels' =>
      '<tv-channels><channel><number>7.1</number><name>Local</name>'
          '</channel></tv-channels>',
    '/query/tv-active-channel' =>
      '<tv-channel><channel><active-input>false</active-input>'
          '</channel></tv-channel>',
    '/query/active-app' =>
      '<active-app><app id="12">Netflix</app></active-app>',
    '/query/media-player' =>
      '<player state="play"><plugin id="12" name="Netflix"/>'
          '<position>1000 ms</position><duration>5000 ms</duration></player>',
    _ => '',
  };
}
