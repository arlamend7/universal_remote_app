import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:remote_driver_runtime/remote_v2.dart';

import 'support/parity_recorder.dart';

/// A loopback Remote v2 endpoint that offers keys, IME, volume and app links.
///
/// By default it reproduces the recorded baseline exactly. Tests can vary the
/// offered feature bits, the `RemoteDeviceInfo` the TV reports (configure
/// field 2) and the audio-output mode; these are documented protocol shapes,
/// not captures from a specific TV.
final class AndroidTvParityServer {
  AndroidTvParityServer(
    this.recorder, {
    this.features = defaultFeatures,
    this.deviceInfo,
    this.audioMode = 2,
  });

  static const defaultFeatures = 35 | 64 | 4 | 512;

  final ParityRecorder recorder;
  final int features;
  final Map<int, Object>? deviceInfo;

  /// Remote v2 audio-output mode (2 absolute, 1 adjustable); null sends no
  /// audio report.
  final int? audioMode;
  SecureServerSocket? _server;
  final _channels = <FramedSocket>[];

  int get port => _server!.port;

  Future<void> start(ClientIdentity tv, ClientIdentity client) async {
    final context = tv.context()
      ..setTrustedCertificatesBytes(utf8.encode(client.certificate));
    final server = _server = await SecureServerSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
      context,
      requestClientCertificate: true,
      requireClientCertificate: true,
    );
    server.listen((socket) => unawaited(_serve(FramedSocket(socket))));
  }

  Future<void> close() async {
    for (final channel in _channels) {
      channel.close();
    }
    await _server?.close();
  }

  Future<void> _serve(FramedSocket channel) async {
    _channels.add(channel);
    final info = deviceInfo;
    channel.send({
      1: WireMessage.encode({
        1: features,
        if (info != null) 2: WireMessage.encode(info),
      }),
    });
    if (audioMode case final mode?) {
      channel.send({
        50: WireMessage.encode({1: 3, 4: mode, 6: 25, 7: 10, 8: 1}),
      });
    }
    channel
      ..send({
        20: WireMessage.encode({
          1: WireMessage.encode({1: 9, 2: 1, 6: 3, 12: 'com.example.tv'}),
          2: WireMessage.encode({1: 4, 3: 2, 4: 5}),
        }),
      })
      ..send({2: <int>[]});
    await _record(channel);
  }

  Future<void> _record(FramedSocket channel) async {
    try {
      while (true) {
        final message = await channel.next();
        if (message == null) {
          return;
        }
        recorder.add({'remoteV2': _describe(message)});
      }
    } on Object {
      return;
    }
  }

  Map<String, Object?> _describe(Map<int, Object> message) => {
    for (final entry in message.entries) '${entry.key}': _payload(entry.value),
  };

  Object? _payload(Object value) {
    if (value is! List<int>) {
      return value;
    }
    try {
      return {
        for (final entry in WireMessage.decode(value).entries)
          '${entry.key}': entry.value is List<int>
              ? base64Encode(entry.value as List<int>)
              : entry.value,
      };
    } on Object {
      return base64Encode(value);
    }
  }
}
