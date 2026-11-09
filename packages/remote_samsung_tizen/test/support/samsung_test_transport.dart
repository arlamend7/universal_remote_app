import 'dart:async';
import 'dart:convert';

import 'package:remote_network/remote_network.dart';

final class SamsungTestTransport implements TextTransport {
  SamsungTestTransport({this.reportApps = true});

  final bool reportApps;
  final _frames = StreamController<String>();
  final sent = <Map<String, dynamic>>[];

  @override
  Stream<String> get messages => _frames.stream;

  void receive(Map<String, Object> frame) => _frames.add(jsonEncode(frame));

  @override
  void send(String message) {
    final decoded = jsonDecode(message) as Map<String, dynamic>;
    sent.add(decoded);
    if (decoded['params'] case {'event': 'ed.installedApp.get'}) {
      receive({
        'event': 'ed.installedApp.get',
        'data': {
          'data': [
            if (reportApps) {'appId': '123', 'name': 'Example'},
            if (reportApps) {'appId': '../bad', 'name': 'Invalid'},
          ],
        },
      });
    }
  }

  @override
  Future<void> close() async {
    if (!_frames.isClosed) {
      await _frames.close();
    }
  }
}
