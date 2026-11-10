import 'dart:async';
import 'dart:convert';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import 'connection/open_samsung_transport.dart';
import 'connection/samsung_credentials.dart';
import 'connection/samsung_endpoint.dart';
import 'protocol/samsung_session.dart';

final class SamsungController extends TVRemoteBase {
  SamsungController(
    this.device,
    this.credentials,
    this._wake,
    this.canWake, {
    this.openTransport = openSamsungTransport,
  });

  @override
  final RemoteDevice device;
  final CredentialStore credentials;
  final Future<void> Function() _wake;
  final Future<TextTransport> Function(Uri, String) openTransport;
  @override
  final bool canWake;
  final _states = StreamController<DeviceConnectionState>.broadcast();
  SamsungSession? _session;
  List<DeviceApplication> _apps = const [];
  int _attempt = 0;
  bool _disposed = false;

  @override
  DeviceConnectionState state = DeviceConnectionState.disconnected;
  @override
  Stream<DeviceConnectionState> get connectionStates => _states.stream;

  @override
  List<CapabilityEvidence> get evidence => [
    if (state == DeviceConnectionState.connected)
      for (final capability in [
        RemoteCapability.navigation,
        RemoteCapability.numericKeys,
        RemoteCapability.specialKeys,
        RemoteCapability.inputs,
        RemoteCapability.mute,
        RemoteCapability.applications,
        RemoteCapability.volume,
        RemoteCapability.channels,
        RemoteCapability.media,
        RemoteCapability.power,
      ])
        CapabilityEvidence(
          capability,
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
    _state(DeviceConnectionState.connecting);
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
    final pin = device.metadata['trustedCertificateDer'];
    if (pin == null || pin.isEmpty) {
      throw const RemoteException(
        'tls',
        'Review the Samsung TV certificate before pairing.',
      );
    }
    final token = samsungToken(await credentials.read(device.id), pin);
    _ensureCurrent(attempt);
    final session = await _open(pin, token, attempt);
    final issued = await _authorize(session, token, attempt);
    _ensureCurrent(attempt);
    if (issued != null && issued != token) {
      await credentials.write(device.id, encodeSamsungToken(pin, issued));
    }
    _ensureCurrent(attempt);
    _apps = await session.loadApplications();
    _ensureCurrent(attempt);
    if (session.isClosed) {
      throw const RemoteException(
        'network',
        'The Samsung TV connection closed.',
      );
    }
    _state(DeviceConnectionState.connected);
  }

  Future<SamsungSession> _open(String pin, String? token, int attempt) async {
    final endpoint = samsungEndpoint(device.endpoints.single.host).replace(
      queryParameters: {
        'name': base64Encode(utf8.encode('Universal Remote')),
        if (token != null) 'token': token,
      },
    );
    final transport = await openTransport(endpoint, pin);
    if (attempt != _attempt) {
      await transport.close();
      _ensureCurrent(attempt);
    }
    return _session = SamsungSession(transport, () => _sessionClosed(attempt));
  }

  Future<String?> _authorize(
    SamsungSession session,
    String? token,
    int attempt,
  ) async {
    if (token == null) {
      _state(DeviceConnectionState.pairing);
    }
    try {
      return await session.authorize(const Duration(seconds: 35));
    } on RemoteException catch (error) {
      if (attempt == _attempt &&
          token != null &&
          error.code == 'pairingDenied') {
        await credentials.delete(device.id);
      }
      rethrow;
    }
  }

  void _sessionClosed(int attempt) {
    if (attempt == _attempt && state == DeviceConnectionState.connected) {
      unawaited(disconnect());
    }
  }

  void _ensureCurrent(int attempt) {
    if (_disposed || attempt != _attempt) {
      throw const RemoteException(
        'cancelled',
        'The Samsung TV connection was canceled.',
      );
    }
  }

  void _state(DeviceConnectionState next) {
    if (next == state || _states.isClosed) {
      return;
    }
    state = next;
    _states.add(next);
  }

  @override
  Future<void> disconnect() async {
    _attempt++;
    final session = _session;
    _session = null;
    _apps = const [];
    _state(DeviceConnectionState.disconnected);
    await session?.close();
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

  SamsungSession get _active {
    final session = _session;
    if (session == null || state != DeviceConnectionState.connected) {
      throw const RemoteException(
        'network',
        'Connect to the Samsung TV first.',
      );
    }
    return session;
  }

  Future<void> _key(String key) async => _active.key(key);

  @override
  Future<void> wake() => _wake();
  @override
  Future<void> powerOff() => _key('KEY_POWER');
  @override
  Future<void> volumeUp() => _key('KEY_VOLUP');
  @override
  Future<void> volumeDown() => _key('KEY_VOLDOWN');
  @override
  Future<void> channelUp() => _key('KEY_CHUP');
  @override
  Future<void> channelDown() => _key('KEY_CHDOWN');

  @override
  Future<void> press(NavigationKey key) => _key(switch (key) {
    NavigationKey.up => 'KEY_UP',
    NavigationKey.down => 'KEY_DOWN',
    NavigationKey.left => 'KEY_LEFT',
    NavigationKey.right => 'KEY_RIGHT',
    NavigationKey.enter => 'KEY_ENTER',
    NavigationKey.back => 'KEY_RETURN',
    NavigationKey.home => 'KEY_HOME',
  });

  @override
  Future<void> sendMedia(MediaAction action) => _key(switch (action) {
    MediaAction.play => 'KEY_PLAY',
    MediaAction.pause => 'KEY_PAUSE',
    MediaAction.stop => 'KEY_STOP',
    MediaAction.rewind => 'KEY_REWIND',
    MediaAction.fastForward => 'KEY_FF',
  });

  @override
  Future<void> sendKey(RemoteKey key) => switch (key) {
    RemoteKey.dash || RemoteKey.replay => _unsupported(),
    RemoteKey.guide => _key('KEY_GUIDE'),
    _ => _key('KEY_${key.wireName}'),
  };

  @override
  Future<void> sendEnter() => press(NavigationKey.enter);
  @override
  Future<List<DeviceApplication>> applications() async => _apps;
  @override
  Set<String>? get reportedApplicationIds =>
      _apps.isEmpty ? null : {for (final app in _apps) app.id};

  @override
  Future<void> launchApplication(String id) async {
    if (!RegExp(r'^[a-zA-Z0-9._-]{1,128}$').hasMatch(id)) {
      throw const RemoteException('appId', 'Enter a valid Samsung app ID.');
    }
    await _active.launch(id);
  }

  Future<Never> _unsupported() => Future.error(
    const RemoteException(
      'unsupported',
      'This command is unavailable on Samsung TV.',
    ),
  );

  @override
  Future<void> setVolume(int volume) => _unsupported();
  @override
  Future<void> setMuted(bool muted) => _unsupported();
  @override
  Future<void> toggleMute() => sendKey(RemoteKey.mute);
  @override
  Future<VolumeState> readVolume() => _unsupported();
  @override
  Stream<VolumeState> watchVolume() => const Stream.empty();
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
  Future<void> sendText(String text) => _unsupported();
  @override
  Future<List<DeviceInput>> inputs() async => const [];
  @override
  Future<void> selectInput(String id) => _unsupported();
  @override
  Future<void> openInputPicker() => sendKey(RemoteKey.source);
  @override
  Future<String?> currentApplication() => _unsupported();
  @override
  Future<CurrentContent> currentContent() => _unsupported();
  @override
  Stream<CurrentContent> watchCurrentContent() => const Stream.empty();
}
