import 'dart:async';

import 'package:remote_core/remote_core.dart';

import 'protocol/android_pairing.dart';
import 'protocol/android_remote_session.dart';
import 'security/client_identity.dart';
import 'security/paired_identity.dart';

final class AndroidTvController extends TVRemoteBase
    implements PairingCodeReceiver {
  AndroidTvController(this.device, this.credentials);

  @override
  final RemoteDevice device;
  final CredentialStore credentials;
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

  @override
  List<CapabilityEvidence> get evidence => [
    if (state == DeviceConnectionState.connected &&
        (_session!.features & 2) != 0)
      for (final capability in [
        RemoteCapability.navigation,
        RemoteCapability.accessorySettings,
        RemoteCapability.media,
        RemoteCapability.volume,
      ])
        CapabilityEvidence(
          capability,
          CapabilitySource.driver,
          CapabilityAvailability.known,
        ),
    if (state == DeviceConnectionState.connected &&
        (_session!.features & 34) == 34)
      const CapabilityEvidence(
        RemoteCapability.power,
        CapabilitySource.driver,
        CapabilityAvailability.known,
      ),
  ];

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
    _session?.close();
    _session = null;
    _setState(DeviceConnectionState.disconnected);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await disconnect();
    await _states.close();
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
  bool get canWake => false;
  @override
  Future<void> wake() => _unsupported();
  @override
  Future<void> powerOff() =>
      supports(RemoteCapability.power) ? _key(223) : _unsupported();
  @override
  Future<void> openAccessorySettings() =>
      _key(AndroidRemoteSession.settingsKey);
  @override
  Future<void> volumeUp() => _key(24);
  @override
  Future<void> volumeDown() => _key(25);
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
  Future<void> sendMedia(MediaAction action) => _key(switch (action) {
    MediaAction.play => 126,
    MediaAction.pause => 127,
    MediaAction.stop => 86,
    MediaAction.rewind => 89,
    MediaAction.fastForward => 90,
  });

  @override
  Future<void> setVolume(int volume) => _unsupported();
  @override
  Future<void> setMuted(bool muted) => _unsupported();
  @override
  Future<VolumeState> readVolume() => _unsupported();
  @override
  Stream<VolumeState> watchVolume() => const Stream.empty();
  @override
  Future<void> channelUp() => _unsupported();
  @override
  Future<void> channelDown() => _unsupported();
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
  Future<void> sendKey(RemoteKey key) => _unsupported();
  @override
  Future<void> sendText(String text) => _unsupported();
  @override
  Future<void> sendEnter() => _unsupported();
  @override
  Future<List<DeviceInput>> inputs() => _unsupported();
  @override
  Future<void> selectInput(String id) => _unsupported();
  @override
  Future<List<DeviceApplication>> applications() => _unsupported();
  @override
  Future<void> launchApplication(String id) => _unsupported();
  @override
  Future<String?> currentApplication() => _unsupported();
  @override
  Future<CurrentContent> currentContent() => _unsupported();
  @override
  Stream<CurrentContent> watchCurrentContent() => const Stream.empty();
}
