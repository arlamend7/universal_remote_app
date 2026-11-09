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
  static const channelUpKey = 166;
  static const channelDownKey = 167;
  static const keyFeature = 2;
  static const powerFeature = 32;
  static const volumeFeature = 64;

  final _volumes = StreamController<VolumeState>.broadcast();
  Stream<VolumeState> get volumes => _volumes.stream;
  VolumeState? volume;
  bool get supportsKeys => features & keyFeature != 0;
  bool get supportsPower => supportsKeys && features & powerFeature != 0;
  bool get supportsVolumeKeys => supportsKeys;

  final String host;
  final int port;
  final PairedIdentity identity;
  final _ready = Completer<bool>();
  FramedSocket? _channel;
  bool _closed = false;
  bool _configured = false;
  int features = 0;

  Future<void> connect(void Function() onClosed) async {
    final socket = await _openSocket();
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

  Future<SecureSocket> _openSocket() async {
    try {
      return await SecureSocket.connect(
        host,
        port,
        context: identity.client.context(),
        onBadCertificate: _matches,
        timeout: const Duration(seconds: 8),
      );
    } on HandshakeException {
      throw const RemoteException(
        'certificate',
        'The paired TV TLS connection could not be verified.',
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
    if (message[50] case final List<int> payload
        when features & volumeFeature != 0) {
      _readVolume(payload);
    }
    if (message[8] case final List<int> payload) {
      _send(9, {1: WireMessage.decode(payload)[1] as int? ?? 0});
    }
  }

  void _configure(List<int> payload) {
    final offered = WireMessage.decode(payload)[1] as int? ?? 0;
    features = offered & (1 | keyFeature | powerFeature | volumeFeature);
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

  void _readVolume(List<int> payload) {
    final fields = WireMessage.decode(payload);
    final maximum = fields[6];
    final level = fields[7] ?? 0;
    final muted = fields[8] ?? 0;
    if (maximum is! int ||
        maximum <= 0 ||
        level is! int ||
        level < 0 ||
        level > maximum ||
        (muted != 0 && muted != 1)) {
      return;
    }
    final reading = VolumeState((100 * level / maximum).round(), muted == 1);
    volume = reading;
    _volumes.add(reading);
  }

  Future<void> key(int code) async {
    if (_closed || !_ready.isCompleted || !supportsKeys) {
      throw const RemoteException('remote', 'TV key commands are unavailable.');
    }
    _send(10, {1: code, 2: 3});
    await _channel!.socket.flush();
  }

  void _send(int field, Map<int, Object> payload) =>
      _channel!.send({field: WireMessage.encode(payload)});

  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    unawaited(_volumes.close());
    _channel?.close();
    _channel = null;
    if (!_ready.isCompleted) {
      _ready.complete(false);
    }
  }
}
