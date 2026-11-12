import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import '../support/fake_transport.dart';
import '../support/memory_credentials.dart';
import '../support/standard_responses.dart';
import 'support/parity_recorder.dart';
import 'support/parity_targets.dart';
import 'support/recording_transport.dart';

/// The LG webOS fixture: one SSAP socket and one pointer socket per session.
final class LgWebOsParityFixture {
  LgWebOsParityFixture({this.overrides = const {}});

  /// SSAP URIs answered with a fixed payload, or rejected when null.
  final Map<String, Map<String, Object?>?> overrides;
  final recorder = ParityRecorder();
  final credentials = MemoryCredentials();

  static const targets = ParityTargets(
    channelId: 'channel-7',
    inputId: 'HDMI_2',
    applicationId: 'device.actual.app',
    accessoryId: '00:11:22:33:44:55',
  );

  RemoteDevice device({bool secure = false}) => RemoteDevice(
    id: 'lg.webos:uuid:parity',
    name: 'Parity LG',
    providerId: 'lg.webos',
    manufacturer: 'LG',
    endpoints: [
      Uri.parse(secure ? 'wss://192.168.1.20:3001' : 'ws://192.168.1.20:3000'),
    ],
    metadata: {if (!secure) 'allowInsecure': 'true'},
  );

  Future<TextTransport> connect(Uri endpoint) async {
    final socket = FakeTransport();
    final pointer = endpoint.path == '/pointer';
    if (!pointer) {
      standardResponses(socket);
      _override(socket);
    }
    return RecordingTransport(socket, recorder, pointer ? 'pointer' : 'ssap');
  }

  void _override(FakeTransport socket) {
    final standard = socket.respond!;
    socket.respond = (request) {
      final uri = request['uri'];
      if (!overrides.containsKey(uri)) {
        standard(request);
        return;
      }
      final payload = overrides[uri];
      if (payload == null) {
        socket.reject(request, '404 no such service');
        return;
      }
      socket.reply(request, payload);
    };
  }
}
