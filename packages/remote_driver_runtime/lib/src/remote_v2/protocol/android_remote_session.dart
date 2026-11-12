import 'dart:async';
import 'dart:io';

import 'package:remote_core/remote_core.dart';

import '../security/paired_identity.dart';
import '../security/pairing_proof.dart';
import 'android_audio_output.dart';
import 'android_device_info.dart';
import 'android_editor.dart';
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
  static const imeFeature = 4;
  static const appLinksFeature = 512;
  final _editor = AndroidEditor();
  final _contents = StreamController<CurrentContent>.broadcast();
  Stream<CurrentContent> get contents => _contents.stream;
  CurrentContent? content;
  AndroidAudioOutput? _output;
  bool get supportsIme => features & imeFeature != 0;
  bool get supportsAppLinks => features & appLinksFeature != 0;
  bool get supportsAbsoluteVolume => _output?.absolute == true;
  bool get supportsMute => _output?.adjustable == true;

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

  /// What the TV reported about itself, when it did.
  AndroidDeviceInfo? deviceInfo;

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
        'The paired TV TLS connection could not be verified. If the TV '
            'was reset or no longer lists this device, re-pair it.',
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
    if (supportsIme) {
      _receiveEditor(message);
    }
    if (message[8] case final List<int> payload) {
      _send(9, {1: WireMessage.decode(payload)[1] as int? ?? 0});
    }
  }

  void _configure(List<int> payload) {
    final configure = WireMessage.decode(payload);
    final offered = configure[1] as int? ?? 0;
    deviceInfo = AndroidDeviceInfo.parse(configure[2]) ?? deviceInfo;
    features =
        offered &
        (1 |
            keyFeature |
            powerFeature |
            volumeFeature |
            imeFeature |
            appLinksFeature);
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
    final output = AndroidAudioOutput.parse(WireMessage.decode(payload));
    if (output == null) {
      return;
    }
    _output = output;
    volume = output.reading;
    _volumes.add(output.reading);
  }

  void _receiveEditor(Map<int, Object> message) {
    if (message[20] case final List<int> payload) {
      _editor.focus(payload);
      final package = _editor.package;
      if (package != null &&
          RegExp(r'^[a-zA-Z0-9_.]{1,200}$').hasMatch(package)) {
        final reported = CurrentContent(appId: package);
        content = reported;
        _contents.add(reported);
      }
    }
    if (message[22] case final List<int> payload) {
      _editor.receiveText(payload);
    }
    if (message[23] case final List<int> payload) {
      _editor.selection(payload);
    }
    if (message.containsKey(24) || _editorClosed(message[21])) {
      _editor.reset();
    }
  }

  bool _editorClosed(Object? payload) =>
      payload is List<int> && (WireMessage.decode(payload)[1] ?? 0) == 0;

  Future<void> text(String text) {
    if (!supportsIme || text.length > 512) {
      throw const RemoteException(
        'text',
        'Send up to 512 characters to a compatible TV field.',
      );
    }
    return _write(21, _editor.text(text));
  }

  Future<void> submit() {
    final edit = _editor.submit;
    if (edit == null) {
      throw const RemoteException(
        'keyboardFocus',
        'The TV did not report a submit action.',
      );
    }
    return _write(21, edit);
  }

  Future<void> launchLink(String url) {
    if (!supportsAppLinks) {
      throw const RemoteException(
        'unsupported',
        'App links are unavailable on this TV.',
      );
    }
    return _write(90, {1: url});
  }

  Future<void> setVolume(int percent) {
    final output = _output;
    if (output == null || !output.absolute || percent < 0 || percent > 100) {
      throw const RemoteException(
        'unsupported',
        'Exact volume is unavailable on this TV output.',
      );
    }
    return _write(50, {
      1: output.id,
      2: output.fromPercent(percent),
      3: output.muted ? 1 : 0,
    });
  }

  Future<void> setMuted(bool muted) {
    final output = _output;
    if (output == null || !output.adjustable) {
      throw const RemoteException(
        'unsupported',
        'Mute control is unavailable on this TV output.',
      );
    }
    return output.muted == muted
        ? Future.value()
        : _write(51, {1: output.id, 2: 2});
  }

  Future<void> _write(int field, Map<int, Object> payload) async {
    if (_closed || !_ready.isCompleted) {
      throw const RemoteException(
        'network',
        'The TV remote connection closed.',
      );
    }
    _send(field, payload);
    await _channel!.socket.flush();
  }

  Future<void> key(int code) async {
    if (_closed || !_ready.isCompleted || !supportsKeys) {
      throw const RemoteException('remote', 'TV key commands are unavailable.');
    }
    await _write(10, {1: code, 2: 3});
  }

  void _send(int field, Map<int, Object> payload) =>
      _channel!.send({field: WireMessage.encode(payload)});

  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    unawaited(_volumes.close());
    unawaited(_contents.close());
    _channel?.close();
    _channel = null;
    if (!_ready.isCompleted) {
      _ready.complete(false);
    }
  }
}
