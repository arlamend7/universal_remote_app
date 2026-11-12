import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import '../engines/contracts/content_reading.dart';
import '../engines/contracts/network_operation.dart';
import 'active_session.dart';
import 'integration_plan.dart';
import 'integration_planner.dart';
import 'session_opener.dart';
import 'wake_sender.dart';

/// The single television controller. It knows nothing about manufacturers:
/// the integration plan supplies the engine, mappings and capabilities, and
/// every method runs a declared runtime operation through a gated session.
final class GenericTvController extends TVRemoteBase
    implements PairingCodeReceiver, DeviceWakeAddressSource {
  GenericTvController(
    this._device, {
    required this.planner,
    required this.credentials,
    WakeSender? wakeSender,
  }) : _wake = wakeSender ?? _sendWakeOnLan;

  final IntegrationPlanner planner;
  final CredentialStore credentials;
  final WakeSender _wake;
  RemoteDevice _device;
  ActiveSession? _active;
  IntegrationPlan? _plan;
  Future<void>? _connecting;
  Future<bool> Function(String code)? _pairing;
  StreamSubscription<void>? _facts;
  StreamSubscription<Set<String>>? _unusable;
  final _states = StreamController<DeviceConnectionState>.broadcast();
  final _changes = StreamController<void>.broadcast();
  final _inputs = StreamController<DeviceInput?>.broadcast();
  DeviceInput? _currentInput;
  Set<String>? _reportedApplicationIds;
  Timer? _retry;
  int _retries = 0;
  int _generation = 0;
  bool _wanted = false;
  bool _disposed = false;

  @override
  DeviceConnectionState state = DeviceConnectionState.disconnected;

  @override
  RemoteDevice get device => _device;

  /// The active plan, for diagnostics (integration, profile, mappings).
  IntegrationPlan? get plan => _active?.plan ?? _plan;

  @override
  Stream<DeviceConnectionState> get connectionStates => _states.stream;

  @override
  Stream<void> get capabilityChanges => _changes.stream;

  @override
  List<CapabilityEvidence> get evidence => _connected == null
      ? const []
      : [for (final item in _connected!.resolved.values) item.evidence];

  @override
  DeviceSoftwareInformation? get sessionSoftwareInformation =>
      _connected?.software;

  @override
  String? get verifiedPeerIdentity => _connected?.session.verifiedPeerIdentity;

  @override
  String? get reportedDiscoveryIdentity =>
      _connected?.session.reportedDiscoveryIdentity;

  ActiveSession? get _connected =>
      state == DeviceConnectionState.connected ? _active : null;

  @override
  Future<void> connect() {
    if (_disposed) {
      return Future.error(
        const RemoteException('disposed', 'This device session is disposed.'),
      );
    }
    if (state == DeviceConnectionState.connected) {
      return Future.value();
    }
    _wanted = true;
    _retry?.cancel();
    return _connecting ??= _connect().whenComplete(() => _connecting = null);
  }

  Future<void> _connect() async {
    final generation = ++_generation;
    bool current() => !_disposed && generation == _generation;
    _setState(DeviceConnectionState.connecting);
    try {
      final plan = _plan = await planner.prepare(_device);
      final opener = SessionOpener(
        planner: planner,
        credentials: credentials,
        onState: _setState,
        onPairingCode: (submit) => _pairing = submit,
      );
      final active = await opener.open(_device, plan, current);
      await _attach(active, generation);
    } catch (_) {
      if (current()) {
        _setState(DeviceConnectionState.disconnected);
      }
      rethrow;
    }
  }

  Future<void> _attach(ActiveSession active, int generation) async {
    _active = active;
    _plan = active.plan;
    _device = _describe(active);
    active.resolve(model: _device.model);
    _facts = active.session.factChanges.listen((_) => _refresh());
    _unusable = active.session.unavailable.listen(_markUnusable);
    unawaited(active.session.lost.then((_) => _lost(generation)));
    _retries = 0;
    _setState(DeviceConnectionState.connected);
    await planner.remember(active.plan, _device);
  }

  RemoteDevice _describe(ActiveSession active) {
    final software = active.software;
    final category = active.plan.definition.session.categoryFor(
      active.session.facts,
    );
    return copyDevice(
      _device,
      model: software?.model ?? _device.model,
      category: category ?? _device.category,
      softwareInformation: software ?? _device.softwareInformation,
      metadata: {..._device.metadata, ...active.plan.metadata},
    );
  }

  void _refresh() {
    _active?.resolve(model: _device.model);
    _emitChange();
  }

  void _markUnusable(Set<String> kinds) {
    _active?.unusableKinds.addAll(kinds);
    _refresh();
  }

  void _emitChange() {
    if (state == DeviceConnectionState.connected && !_changes.isClosed) {
      _changes.add(null);
    }
  }

  Future<void> _lost(int generation) async {
    if (generation != _generation || _disposed) {
      return;
    }
    await _close();
    final attempts = _plan?.definition.session.reconnectAttempts ?? 0;
    if (!_wanted || _retries >= attempts) {
      return;
    }
    final attempt = ++_retries;
    _setState(DeviceConnectionState.reconnecting);
    _retry = Timer(Duration(seconds: 1 << (attempt - 1)), _reconnect);
  }

  Future<void> _reconnect() async {
    if (!_wanted || _disposed) {
      return;
    }
    try {
      await connect();
    } on Object {
      unawaited(_lost(_generation));
    }
  }

  Future<void> _close() async {
    final active = _active;
    _active = null;
    _currentInput = null;
    _reportedApplicationIds = null;
    _pairing = null;
    await _facts?.cancel();
    await _unusable?.cancel();
    _setState(DeviceConnectionState.disconnected);
    if (active == null) {
      return;
    }
    planner.release(active.plan);
    await active.session.close();
  }

  @override
  Future<void> disconnect() async {
    _wanted = false;
    ++_generation;
    _retry?.cancel();
    await _close();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await disconnect();
    await _states.close();
    await _changes.close();
    await _inputs.close();
  }

  @override
  Future<bool> submitPairingCode(String code) async =>
      await _pairing?.call(code) ?? false;

  void _setState(DeviceConnectionState next) {
    if (state == next || _states.isClosed) {
      return;
    }
    state = next;
    _states.add(next);
  }

  /// Runs [operation] after gating it; declared failure codes withdraw the
  /// capability for the rest of the session.
  Future<Object?> _run(
    String operation, [
    Map<String, Object?> arguments = const {},
  ]) async {
    final active = _connected;
    if (active == null) {
      throw const RemoteException('disconnected', 'Connect to the TV first.');
    }
    final gate = active.gate;
    final mapping = gate.require(operation);
    gate.check(mapping, arguments);
    try {
      return await active.session.execute(mapping.operation, arguments);
    } on RemoteException catch (error) {
      _withdraw(active, operation, error);
      rethrow;
    }
  }

  void _withdraw(
    ActiveSession active,
    String operation,
    RemoteException error,
  ) {
    final capability = active.gate.withdraws(operation, error);
    if (capability == null || !identical(active, _active)) {
      return;
    }
    active.withdrawn[capability] =
        'The TV rejected or disconnected this control.';
    _refresh();
  }

  bool _mapped(String operation) => _connected?.table.has(operation) == true;

  Future<void> _send(
    String operation, [
    Map<String, Object?> args = const {},
  ]) => _run(operation, args);

  Future<T> _read<T>(
    String operation, [
    Map<String, Object?> args = const {},
  ]) async => await _run(operation, args) as T;

  Future<void> _target(String operation, String target) {
    if (target.trim().isEmpty) {
      throw ArgumentError.value(target, 'target', 'A target is required.');
    }
    return _send(operation, {'target': target});
  }

  @override
  bool get canWake {
    final mapping = _plan?.definition.operations(_plan!.profile)['wake'];
    if (mapping == null) {
      return false;
    }
    if (mapping.operation is NetworkOperation) {
      return normalizeMacAddress(_device.metadata['macAddress']) != null;
    }
    return _connected?.gate.allows('wake') == true;
  }

  @override
  Future<void> wake() async {
    final mapping = _plan?.definition.operations(_plan!.profile)['wake'];
    final network = mapping?.operation;
    if (network is! NetworkOperation) {
      return _send('wake');
    }
    final mac = normalizeMacAddress(_device.metadata['macAddress']);
    if (mac == null) {
      throw const RemoteException(
        'wakeUnavailable',
        'Configure a verified MAC address and enable network wake on the TV first.',
      );
    }
    await _wake(
      mac,
      _device.metadata['broadcastAddress'] ??
          network.broadcast ??
          '255.255.255.255',
    );
  }

  @override
  Future<void> powerOff() => _send('power-off');
  @override
  Future<void> volumeUp() => _send('volume-up');
  @override
  Future<void> volumeDown() => _send('volume-down');
  @override
  Future<void> setVolume(int volume) => _send('set-volume', {'volume': volume});
  @override
  Future<void> setMuted(bool muted) => _send('set-mute', {'muted': muted});

  @override
  Future<void> toggleMute() async {
    if (_mapped('toggle-mute')) {
      return _send('toggle-mute');
    }
    final active = _connected;
    final reading = active?.table['read-volume'];
    if (active == null || reading == null || !active.gate.allows('set-mute')) {
      return _send('set-mute', const {'muted': true});
    }
    final volume = await active.session.execute(reading.operation, const {});
    final muted = volume is VolumeState ? volume.muted ?? false : false;
    await setMuted(!muted);
  }

  @override
  Future<VolumeState> readVolume() => _read<VolumeState>('read-volume');

  @override
  Stream<VolumeState> watchVolume() =>
      _subscribe<VolumeState>('subscribe-volume');

  @override
  Future<void> press(NavigationKey key) =>
      _send(RuntimeOperations.navigation(key));
  @override
  Future<void> channelUp() => _send('channel-up');
  @override
  Future<void> channelDown() => _send('channel-down');
  @override
  Future<List<DeviceChannel>> channels() =>
      _read<List<DeviceChannel>>('list-channels');
  @override
  Future<void> selectChannel(String id) => _target('select-channel', id);
  @override
  Future<void> sendMedia(MediaAction action) =>
      _send(RuntimeOperations.media(action));
  @override
  Future<void> togglePlayback() => _send('toggle-playback');

  @override
  Future<bool?> playbackState() async =>
      _mapped('read-playback') ? _read<bool?>('read-playback') : null;

  @override
  Future<void> turnOffScreen() => _send('screen-off');
  @override
  Future<void> turnOnScreen() => _send('screen-on');
  @override
  Future<void> movePointer(double dx, double dy) =>
      _send('pointer-move', {'dx': dx, 'dy': dy});
  @override
  Future<void> scroll(double dx, double dy) =>
      _send('pointer-scroll', {'dx': dx, 'dy': dy});
  @override
  Future<void> click() => _send('pointer-click');
  @override
  Future<void> sendKey(RemoteKey key) => _send(RuntimeOperations.key(key));
  @override
  Future<void> sendText(String text) => _send('send-text', {'text': text});
  @override
  Future<void> sendEnter() => _send('send-enter');

  @override
  Future<List<DeviceInput>> inputs() async => _mapped('list-inputs')
      ? await _read<List<DeviceInput>>('list-inputs')
      : const [];

  @override
  Future<void> selectInput(String id) => _target('select-input', id);
  @override
  Future<void> openInputPicker() => _send('open-input-picker');
  @override
  DeviceInput? get currentInput => _currentInput;
  @override
  Stream<DeviceInput?> get currentInputChanges => _inputs.stream;

  @override
  Future<List<DeviceApplication>> applications() async {
    if (!_mapped('list-applications')) {
      return const [];
    }
    final apps = await _read<List<DeviceApplication>>('list-applications');
    _reportedApplicationIds = Set.unmodifiable(apps.map((app) => app.id));
    return apps;
  }

  @override
  Set<String>? get reportedApplicationIds => _reportedApplicationIds;

  @override
  Future<void> launchApplication(String id) =>
      _send('launch-application', {'target': id});

  @override
  Future<String?> currentApplication() async => _mapped('read-application')
      ? await _read<String?>('read-application')
      : (await currentContent()).appId;

  @override
  Future<CurrentContent> currentContent() async =>
      _content(await _run('read-content'));

  @override
  Stream<CurrentContent> watchCurrentContent() =>
      _subscribe<Object?>('subscribe-content').map(_content);

  CurrentContent _content(Object? value) {
    final reading = value is ContentReading
        ? value
        : ContentReading(value! as CurrentContent);
    if (reading.reportsInput && reading.input?.id != _currentInput?.id) {
      _currentInput = reading.input;
      _inputs.add(reading.input);
    }
    return reading.content;
  }

  @override
  Future<List<BluetoothAccessory>> bluetoothAccessories() =>
      _read<List<BluetoothAccessory>>('list-accessories');
  @override
  Future<void> toggleBluetoothAccessory(String id) =>
      _target('toggle-accessory', id);
  @override
  Future<void> openAccessorySettings() => _send('open-accessory-settings');
  @override
  Future<void> startVoiceControl() => _send('start-voice');
  @override
  Future<void> toggleGameMode() => _send('toggle-game-mode');

  @override
  Future<DeviceWakeAddress?> readWakeAddress() async {
    if (!_mapped('read-wake-address')) {
      return null;
    }
    try {
      return await _read<DeviceWakeAddress?>('read-wake-address');
    } on Object {
      return null;
    }
  }

  Stream<T> _subscribe<T>(String operation) {
    final active = _connected;
    final mapping = active?.table[operation];
    if (active == null || mapping == null) {
      return const Stream.empty();
    }
    return active.session.subscribe(mapping.operation).cast<T>();
  }

  static Future<void> _sendWakeOnLan(String mac, String broadcast) =>
      sendWakeOnLan(mac, broadcast: broadcast);
}
