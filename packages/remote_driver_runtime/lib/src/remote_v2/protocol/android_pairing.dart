import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:remote_core/remote_core.dart';

import '../security/client_identity.dart';
import '../security/paired_identity.dart';
import '../security/pairing_proof.dart';
import 'framed_socket.dart';
import 'wire_message.dart';

final class AndroidPairing {
  AndroidPairing(
    this.host,
    this.client, {
    this.port = 6467,
    this.codeTimeout = const Duration(minutes: 2),
    this.stepTimeout = const Duration(seconds: 10),
  });

  final String host;
  final int port;

  /// How long the TV's on-screen code waits for entry.
  final Duration codeTimeout;

  /// How long each pairing message waits for the TV's reply.
  final Duration stepTimeout;
  final ClientIdentity client;
  final _proof = Completer<Uint8List?>();
  FramedSocket? _channel;
  Uint8List? _peer;
  bool _closed = false;

  Future<PairedIdentity> run(void Function() onCodeRequested) async {
    final socket = await SecureSocket.connect(
      host,
      port,
      context: client.context(),
      // Trust is established by the TV's on-screen code and then pinned.
      onBadCertificate: (_) => !_closed,
      timeout: const Duration(seconds: 8),
    );
    if (_closed) {
      socket.destroy();
      throw const RemoteException('cancelled', 'Pairing was canceled.');
    }
    final channel = _channel = FramedSocket(socket);
    try {
      final peer = socket.peerCertificate?.der;
      if (peer == null) {
        throw const RemoteException(
          'certificate',
          'The TV did not present a certificate.',
        );
      }
      await _exchange(channel, 10, {1: 'atvremote', 2: 'Universal Remote'}, 11);
      final encoding = WireMessage.encode({1: 3, 2: 6});
      await _exchange(channel, 20, {1: encoding, 3: 1}, 20);
      await _exchange(channel, 30, {1: encoding, 2: 1}, 31);
      _peer = peer;
      onCodeRequested();
      final secret = await _awaitCode();
      if (secret == null) {
        throw const RemoteException('cancelled', 'Pairing was canceled.');
      }
      await _exchange(channel, 40, {1: secret}, 41);
      return PairedIdentity(client, PairingProof.fingerprint(peer));
    } finally {
      close();
    }
  }

  bool submit(String code) {
    final peer = _peer;
    if (peer == null || _proof.isCompleted || _closed) {
      return false;
    }
    final secret = PairingProof.forCode(code, client.certificateDer, peer);
    if (secret == null) {
      return false;
    }
    _proof.complete(secret);
    return true;
  }

  /// Pairing status codes from the Remote v2 pairing protocol.
  static const _ok = 200;
  static const _badSecret = 402;

  Future<Uint8List?> _awaitCode() async {
    try {
      return await _proof.future.timeout(codeTimeout);
    } on TimeoutException {
      throw const RemoteException(
        'pairingTimeout',
        'The pairing code was not entered in time. Start pairing again.',
      );
    }
  }

  Future<void> _exchange(
    FramedSocket channel,
    int field,
    Map<int, Object> payload,
    int expected,
  ) async {
    channel.send({1: 2, 2: _ok, field: WireMessage.encode(payload)});
    final response = await _response(channel);
    if (response?[2] == _ok && response!.containsKey(expected)) {
      return;
    }
    if (response?[2] == _badSecret) {
      throw const RemoteException(
        'pairingCode',
        'The TV rejected the pairing code. Start pairing again and enter '
            'the code shown on the TV.',
      );
    }
    throw const RemoteException(
      'pairing',
      'The TV rejected the pairing exchange.',
    );
  }

  Future<Map<int, Object>?> _response(FramedSocket channel) async {
    try {
      return await channel.next().timeout(stepTimeout);
    } on TimeoutException {
      throw const RemoteException(
        'timeout',
        'The TV did not answer the pairing request.',
      );
    }
  }

  void close() {
    _closed = true;
    _channel?.close();
    _channel = null;
    if (!_proof.isCompleted) {
      _proof.complete(null);
    }
  }
}
