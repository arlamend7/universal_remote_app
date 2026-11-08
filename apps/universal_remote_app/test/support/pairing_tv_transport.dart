import 'dart:async';
import 'dart:convert';

import 'package:remote_network/remote_network.dart';

/// Simulates PROMPT approval separately from opening the connection.
final class PairingTvTransport implements TextTransport {
  PairingTvTransport({this.denyVolumeFeedback = false});
  final bool denyVolumeFeedback;
  final _incoming = StreamController<String>();
  final requests = <Map<String, dynamic>>[];
  final frames = <String>[];
  bool closed = false;
  bool pointer = false;
  @override
  Stream<String> get messages => _incoming.stream;
  @override
  void send(String frame) {
    frames.add(frame);
    if (pointer) {
      return;
    }
    final request = jsonDecode(frame) as Map<String, dynamic>;
    requests.add(request);
    if (request['type'] == 'register') {
      _reply(request, {'pairingType': 'PROMPT'});
      return;
    }
    if (denyVolumeFeedback && request['uri'] == 'ssap://audio/getVolume') {
      _incoming.add(
        jsonEncode({
          'id': request['id'],
          'type': 'error',
          'error': '403 permission denied',
        }),
      );
      return;
    }
    _reply(request, _payload(request['uri']));
  }

  void approve() => _reply(requests.first, {
    'client-key': 'test-only-paired-key',
  }, type: 'registered');

  Map<String, Object?> _payload(Object? uri) => switch (uri) {
    'ssap://audio/getVolume' => {'volume': 20},
    'ssap://audio/getMute' => {'mute': false},
    'ssap://com.webos.applicationManager/listApps' => {'apps': []},
    'ssap://tv/getExternalInputList' => {'devices': []},
    'ssap://com.webos.service.networkinput/getPointerInputSocket' => {
      'socketPath': 'wss://172.16.1.13:3001/pointer',
    },
    _ => {'returnValue': true},
  };

  void _reply(
    Map<String, dynamic> request,
    Map<String, Object?> payload, {
    String type = 'response',
  }) {
    _incoming.add(
      jsonEncode({'id': request['id'], 'type': type, 'payload': payload}),
    );
  }

  @override
  Future<void> close() async {
    if (closed) {
      return;
    }
    closed = true;
    unawaited(_incoming.close());
  }
}
