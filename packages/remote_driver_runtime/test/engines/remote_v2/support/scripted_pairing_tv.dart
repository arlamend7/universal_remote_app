import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:remote_driver_runtime/remote_v2.dart';

/// How the scripted TV answers one pairing request.
typedef PairingReply = ({int status, bool silent, bool close});

const PairingReply pairingOk = (status: 200, silent: false, close: false);

/// A loopback pairing endpoint (port 6467 role) that follows the documented
/// polo exchange (10→11, 20→20, 30→31, 40→41) and answers each request as
/// scripted. Status codes: 200 OK, 400 ERROR, 401 BAD_CONFIGURATION,
/// 402 BAD_SECRET. Not a capture from a specific TV.
final class ScriptedPairingTv {
  ScriptedPairingTv(
    this.tv,
    this.client, {
    this.replies = const {},
    this.requireClient = true,
  });

  final ClientIdentity tv;

  /// The expected client; ignored when [requireClient] is false (a client
  /// identity generated inside the engine cannot be known in advance).
  final ClientIdentity client;
  final bool requireClient;
  final Map<int, PairingReply> replies;
  final requests = <int>[];
  SecureServerSocket? _server;
  FramedSocket? _channel;

  int get port => _server!.port;

  static const _answers = {10: 11, 20: 20, 30: 31, 40: 41};

  Future<void> start() async {
    final server = _server = await SecureServerSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
      requireClient
          ? (tv.context()
              ..setTrustedCertificatesBytes(utf8.encode(client.certificate)))
          : tv.context(),
      requestClientCertificate: requireClient,
      requireClientCertificate: requireClient,
    );
    server.listen((socket) => unawaited(_serve(FramedSocket(socket))));
  }

  Future<void> close() async {
    _channel?.close();
    await _server?.close();
  }

  Future<void> _serve(FramedSocket channel) async {
    _channel = channel;
    try {
      while (true) {
        final message = await channel.next();
        if (message == null) {
          return;
        }
        if (!_answer(channel, message)) {
          return;
        }
      }
    } on Object {
      return;
    }
  }

  bool _answer(FramedSocket channel, Map<int, Object> message) {
    final request = _answers.keys.where(message.containsKey).firstOrNull;
    if (request == null) {
      return true;
    }
    requests.add(request);
    final reply = replies[request] ?? pairingOk;
    if (reply.close) {
      channel.close();
      return false;
    }
    if (!reply.silent) {
      channel.send({1: 2, 2: reply.status, _answers[request]!: <int>[]});
    }
    return true;
  }
}
