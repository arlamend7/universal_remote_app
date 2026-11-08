import 'dart:async';
import 'dart:io';

import 'package:remote_core/remote_core.dart';

import '../security/paired_identity.dart';
import '../security/pairing_proof.dart';
import 'framed_socket.dart';
import 'wire_message.dart';

final class AndroidRemoteSession {
  AndroidRemoteSession(this.host, this.identity, {this.port = 6466});

  static const settingsKey = 176;

  final String host;
  final int port;
  final PairedIdentity identity;
  final _ready = Completer<bool>();
  FramedSocket? _channel;
  bool _closed = false;
  bool _configured = false;
  int features = 0;

  Future<void> connect(void Function() onClosed) async {
    final socket = await SecureSocket.connect(
      host,
      port,
      context: identity.client.context(),
      onBadCertificate: _matches,
      timeout: const Duration(seconds: 8),
    );
    if (_closed ||
        socket.peerCertificate == null ||
        !_matches(socket.peerCertificate!)) {
      socket.destroy();
      throw const RemoteException(
        'certificate',
        'The TV certificate does not match the paired device.',
      );
    }
    _channel = FramedSocket(socket);
    unawaited(_listen(onClosed));
    if (!await _ready.future.timeout(const Duration(seconds: 10))) {
      throw const RemoteException(
        'remote',
        'The TV did not establish a remote session.',
      );
    }
  }

  bool _matches(X509Certificate certificate) =>
      PairingProof.fingerprint(certificate.der) == identity.fingerprint;

  Future<void> _listen(void Function() onClosed) async {
    try {
      await _readMessages(_channel!);
    } catch (_) {
      // The owner observes the disconnection and can reconnect.
    } finally {
      final report = !_closed && _ready.isCompleted;
      close();
      if (report) {
        onClosed();
      }
    }
  }

  Future<void> _readMessages(FramedSocket channel) async {
    while (true) {
      final message = await channel.next().timeout(
        const Duration(seconds: 140),
      );
      if (message == null) {
        return;
      }
      _receive(message);
    }
  }

  void _receive(Map<int, Object> message) {
    if (message.containsKey(3)) {
      throw const FormatException('Android TV rejected a remote message.');
    }
    if (message[1] case final List<int> payload) {
      _configure(payload);
    }
    if (message.containsKey(2) && _configured) {
      _send(2, {1: features});
      if (!_ready.isCompleted) {
        _ready.complete(true);
      }
    }
    if (message[8] case final List<int> payload) {
      _send(9, {1: WireMessage.decode(payload)[1] as int? ?? 0});
    }
  }

  void _configure(List<int> payload) {
    final offered = WireMessage.decode(payload)[1] as int? ?? 0;
    features = offered & (1 | 2 | 32);
    _configured = true;
    _send(1, {
      1: features,
      2: WireMessage.encode({
        3: Platform.isIOS ? 2 : 1,
        5: 'Universal Remote',
        6: '1.0',
      }),
    });
  }

  Future<void> key(int code) async {
    if (_closed || !_ready.isCompleted || features & 2 == 0) {
      throw const RemoteException('remote', 'TV key commands are unavailable.');
    }
    _send(10, {1: code, 2: 3});
    await _channel!.socket.flush();
  }

  void _send(int field, Map<int, Object> payload) =>
      _channel!.send({field: WireMessage.encode(payload)});

  void close() {
    _closed = true;
    _channel?.close();
    _channel = null;
    if (!_ready.isCompleted) {
      _ready.complete(false);
    }
  }
}
