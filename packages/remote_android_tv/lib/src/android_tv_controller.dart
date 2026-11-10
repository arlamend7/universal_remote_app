import 'dart:async';

import 'package:remote_core/remote_core.dart';

import 'protocol/android_key_codes.dart';
import 'protocol/android_pairing.dart';
import 'protocol/android_remote_session.dart';
import 'security/client_identity.dart';
import 'security/paired_identity.dart';

final class AndroidTvController extends TVRemoteBase
    implements PairingCodeReceiver {
  AndroidTvController(this.device, this.credentials, this._wake, this.canWake);

  @override
  final RemoteDevice device;
  final CredentialStore credentials;
  final Future<void> Function() _wake;
  final _states = StreamController<DeviceConnectionState>.broadcast();
  AndroidPairing? _pairing;
  AndroidRemoteSession? _session;
  int _attempt = 0;
  bool _disposed = false;
  String? _verifiedPeerIdentity;

  @override
  String? get verifiedPeerIdentity => _verifiedPeerIdentity;

  @override
  DeviceConnectionState state = DeviceConnectionState.disconnected;
  @override
  Stream<DeviceConnectionState> get connectionStates => _states.stream;

  final _capabilities = StreamController<void>.broadcast();
  StreamSubscription<VolumeState>? _volumeSubscription;

  @override
  Stream<void> get capabilityChanges => _capabilities.stream;

  @override
  List<CapabilityEvidence> get evidence {
    final session = _session;
    if (state != DeviceConnectionState.connected || session == null) {
      return const [];
    }
    return [
      if (session.supportsKeys) ...[
        _known(RemoteCapability.navigation),
        _known(RemoteCapability.media),
        _known(RemoteCapability.numericKeys),
        _known(RemoteCapability.tvSettings),
        _known(RemoteCapability.specialKeys),
        _known(RemoteCapability.trackNavigation),
        _known(RemoteCapability.voice),
        _known(RemoteCapability.inputs),
        _known(RemoteCapability.mute),
        const CapabilityEvidence(
          RemoteCapability.channels,
          CapabilitySource.driver,
          CapabilityAvailability.known,
          reason: 'Sends channel keys to the active TV input or app.',
        ),
      ],
      if (session.supportsVolumeKeys) _known(RemoteCapability.volume),
      if (session.supportsIme) ...[
        _known(RemoteCapability.textInput),
        _known(RemoteCapability.currentContent),
      ],
      if (session.supportsAppLinks) _known(RemoteCapability.applications),
      if (session.supportsAbsoluteVolume)
        _known(RemoteCapability.absoluteVolume),
      if (session.supportsPower) _known(RemoteCapability.power),
      if (session.volume != null)
        const CapabilityEvidence(
          RemoteCapability.volumeFeedback,
          CapabilitySource.driver,
          CapabilityAvailability.verified,
        ),
    ];
  }

  CapabilityEvidence _known(RemoteCapability capability) => CapabilityEvidence(
    capability,
    CapabilitySource.driver,
    CapabilityAvailability.known,
  );

  @override
  Future<void> connect() async {
    if (_disposed || state != DeviceConnectionState.disconnected) {
      return;
    }
    final attempt = ++_attempt;
    _setState(DeviceConnectionState.connecting);
    try {
      await _connect(attempt);
    } catch (_) {
      if (attempt == _attempt) {
        await disconnect();
      }
      rethrow;
    }
  }

  Future<void> _connect(int attempt) async {
    final host = device.endpoints.single.host;
    final stored = await credentials.read(device.id);
    _ensureCurrent(attempt);
    final identity = stored == null
        ? await _pair(host, attempt)
        : PairedIdentity.decode(stored);
    _ensureCurrent(attempt);
    final session = _session = AndroidRemoteSession(host, identity);
    await session.connect(() => unawaited(disconnect()));
    _ensureCurrent(attempt);
    var audio = (
      session.volume != null,
      session.supportsAbsoluteVolume,
      session.supportsMute,
    );
    _volumeSubscription = session.volumes.listen((_) {
      final next = (
        session.volume != null,
        session.supportsAbsoluteVolume,
        session.supportsMute,
      );
      if (audio != next && identical(_session, session)) {
        audio = next;
        _capabilities.add(null);
      }
    });
    _verifiedPeerIdentity = identity.fingerprint;
    _setState(DeviceConnectionState.connected);
  }

  Future<PairedIdentity> _pair(String host, int attempt) async {
    final client = await ClientIdentity.generate();
    _ensureCurrent(attempt);
    final pairing = _pairing = AndroidPairing(host, client);
    try {
      final identity = await pairing.run(
        () => _setState(DeviceConnectionState.pairing),
      );
      _ensureCurrent(attempt);
      await credentials.write(device.id, identity.encode());
      return identity;
    } finally {
      if (identical(_pairing, pairing)) {
        _pairing = null;
      }
    }
  }

  void _ensureCurrent(int attempt) {
    if (attempt != _attempt || _disposed) {
      throw const RemoteException('cancelled', 'The connection was canceled.');
    }
  }

  void _setState(DeviceConnectionState next) {
    if (state == next || _states.isClosed) {
      return;
    }
    state = next;
    _states.add(next);
  }

  @override
  Future<bool> submitPairingCode(String code) async =>
      _pairing?.submit(code) ?? false;

  @override
  Future<void> disconnect() async {
    _attempt++;
    _pairing?.close();
    _pairing = null;
    final cancellation = _volumeSubscription?.cancel();
    _volumeSubscription = null;
    _session?.close();
    _session = null;
    _setState(DeviceConnectionState.disconnected);
    await cancellation;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await disconnect();
    await _states.close();
    await _capabilities.close();
  }

  Future<void> _key(int code) {
    final session = _session;
    if (session == null || state != DeviceConnectionState.connected) {
      return _unsupported();
    }
    return session.key(code);
  }

  Future<Never> _unsupported() => Future.error(
    const RemoteException(
      'unsupported',
      'This command is unavailable on Android TV.',
    ),
  );

  @override
  final bool canWake;
  @override
  Future<void> wake() => _wake();
  @override
  Future<void> powerOff() =>
      supports(RemoteCapability.power) ? _key(223) : _unsupported();
  @override
  Future<void> openAccessorySettings() => _unsupported();
  @override
  Future<void> volumeUp() =>
      supports(RemoteCapability.volume) ? _key(24) : _unsupported();
  @override
  Future<void> volumeDown() =>
      supports(RemoteCapability.volume) ? _key(25) : _unsupported();
  @override
  Future<void> press(NavigationKey key) => _key(switch (key) {
    NavigationKey.up => 19,
    NavigationKey.down => 20,
    NavigationKey.left => 21,
    NavigationKey.right => 22,
    NavigationKey.enter => 23,
    NavigationKey.back => 4,
    NavigationKey.home => 3,
  });
  @override
  Future<void> sendMedia(MediaAction action) => _key(androidMediaCode(action));

  @override
  Future<void> setVolume(int volume) async =>
      await (_session?.setVolume(volume) ?? _unsupported());
  @override
  Future<void> toggleMute() => sendKey(RemoteKey.mute);
  @override
  Future<void> startVoiceControl() => _key(231);
  @override
  Future<void> setMuted(bool muted) async =>
      await (_session?.setMuted(muted) ?? _unsupported());
  @override
  Future<VolumeState> readVolume() async =>
      _session?.volume ?? await _unsupported();
  @override
  Stream<VolumeState> watchVolume() =>
      _session?.volumes ?? const Stream.empty();
  @override
  Future<void> channelUp() => _key(AndroidRemoteSession.channelUpKey);
  @override
  Future<void> channelDown() => _key(AndroidRemoteSession.channelDownKey);
  @override
  Future<List<DeviceChannel>> channels() => _unsupported();
  @override
  Future<void> selectChannel(String id) => _unsupported();
  @override
  Future<void> movePointer(double dx, double dy) => _unsupported();
  @override
  Future<void> scroll(double dx, double dy) => _unsupported();
  @override
  Future<void> click() => _unsupported();
  @override
  Future<void> sendKey(RemoteKey key) {
    final code = androidKeyCode(key);
    return code == null ? _unsupported() : _key(code);
  }

  @override
  Future<void> sendText(String text) async =>
      await (_session?.text(text) ?? _unsupported());
  @override
  Future<void> sendEnter() async =>
      await (_session?.submit() ?? _unsupported());
  @override
  Future<List<DeviceInput>> inputs() async => const [];
  @override
  Future<void> selectInput(String id) => _unsupported();
  @override
  Future<void> openInputPicker() => sendKey(RemoteKey.source);
  @override
  Future<List<DeviceApplication>> applications() async => const [];

  /// Launches a supported app link, such as vnd.youtube:// or an HTTPS link.
  @override
  Future<void> launchApplication(String target) async {
    final uri = Uri.tryParse(target);
    final safe =
        target == 'vnd.youtube://' ||
        (uri != null &&
            uri.scheme == 'https' &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty);
    if (!safe ||
        target.length > 512 ||
        !supports(RemoteCapability.applications)) {
      throw const RemoteException(
        'appLink',
        'Enter a supported app link, such as vnd.youtube:// or an HTTPS link.',
      );
    }
    await _session!.launchLink(target);
  }

  @override
  Future<String?> currentApplication() async => _session?.content?.appId;
  @override
  Future<CurrentContent> currentContent() async =>
      _session?.content ?? await _unsupported();
  @override
  Stream<CurrentContent> watchCurrentContent() =>
      _session?.contents ?? const Stream.empty();
}
