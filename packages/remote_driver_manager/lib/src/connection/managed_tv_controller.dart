import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';

import '../resolution/driver_match.dart';
import 'driver_tv_capabilities.dart';
import 'driver_tv_response.dart';
import 'managed_driver_service.dart';
import 'managed_tv_session.dart';

/// Maps the supported, named driver commands to the television contract.
final class ManagedTvController extends TVRemoteBase
    implements PairingCodeReceiver {
  ManagedTvController(this._device, this._drivers);

  @override
  RemoteDevice get device => _device;
  RemoteDevice _device;
  DeviceSoftwareInformation? _sessionSoftware;
  @override
  DeviceSoftwareInformation? get sessionSoftwareInformation =>
      state == DeviceConnectionState.connected ? _sessionSoftware : null;
  final ManagedDriverService _drivers;
  final _states = StreamController<DeviceConnectionState>.broadcast();
  final _changes = StreamController<void>.broadcast();
  final _volume = StreamController<VolumeState>.broadcast();
  final _content = StreamController<CurrentContent>.broadcast();
  final _inputs = StreamController<DeviceInput?>.broadcast();
  DeviceInput? _currentInput;
  Set<String>? _reportedApplicationIds;
  bool _installing = false;

  bool get installing => _installing;
  double? installProgress;
  List<DriverMatch> choices = const [];
  Completer<DriverMatch?>? _selection;

  void chooseDriver(DriverMatch match) {
    final selection = _selection;
    if (selection != null &&
        !selection.isCompleted &&
        choices.contains(match)) {
      selection.complete(match);
    }
  }

  @override
  Stream<void> get capabilityChanges => _changes.stream;
  // disconnect closes the active session cancellation stream.
  // ignore: close_sinks
  StreamController<void>? _cancellation;
  DriverBundle? _bundle;
  DriverCompatibility? _profile;
  ManagedTvSession? _persistent;
  ManagedTvSession? _pendingReplacement;
  Completer<String?>? _pairingCode;
  final _rejectedSubscriptions = <String>{};
  final _acknowledged = <String>{};
  Uri? _endpoint;
  bool _disposed = false;

  @override
  DeviceConnectionState state = DeviceConnectionState.disconnected;

  @override
  Stream<DeviceConnectionState> get connectionStates => _states.stream;

  @override
  List<CapabilityEvidence> get evidence {
    final bundle = _bundle;
    if (bundle == null) {
      return const [];
    }
    return [
      for (final capability in bundle.capabilities.keys)
        CapabilityEvidence(
          capability,
          _disabled(capability)
              ? CapabilitySource.profile
              : CapabilitySource.driver,
          _disabled(capability)
              ? CapabilityAvailability.conditional
              : _availability(bundle, capability),
          reason: _disabled(capability)
              ? 'Disabled by the TV software compatibility profile.'
              : _subscriptionReason(capability),
        ),
    ];
  }

  CapabilityAvailability _availability(
    DriverBundle bundle,
    RemoteCapability capability,
  ) {
    final disabled =
        _profile?.disabledCapabilities ?? const <RemoteCapability>{};
    if (!DriverTvCapabilities.supports(
      bundle,
      capability,
      disabled: disabled,
    )) {
      return CapabilityAvailability.advertised;
    }
    final verified = DriverTvCapabilities.supports(
      bundle,
      capability,
      acknowledged: _acknowledged,
      disabled: disabled,
    );
    return verified
        ? CapabilityAvailability.verified
        : CapabilityAvailability.known;
  }

  bool _disabled(RemoteCapability capability) =>
      _profile?.disabledCapabilities.contains(capability) == true;

  String? _subscriptionReason(RemoteCapability capability) {
    final event = switch (capability) {
      RemoteCapability.volumeFeedback => 'volume',
      RemoteCapability.currentContent => 'content',
      RemoteCapability.currentInput => 'input',
      _ => null,
    };
    if (event != null &&
        (_rejectedSubscriptions.contains(event) ||
            _rejectedSubscriptions.contains('*'))) {
      return 'Live updates were declined by the TV. Reads are still available.';
    }
    return null;
  }

  @override
  Future<void> connect() async {
    if (_disposed || state != DeviceConnectionState.disconnected) {
      return;
    }
    final cancellation = _cancellation = StreamController<void>.broadcast();
    _setState(DeviceConnectionState.connecting);
    try {
      await _connect(cancellation);
    } catch (_) {
      if (identical(_cancellation, cancellation)) {
        await disconnect();
      }
      rethrow;
    }
  }

  Future<void> _connect(StreamController<void> cancellation) async {
    var bundle = await _drivers.prepare(
      device,
      cancelled: () => !identical(_cancellation, cancellation),
      onInstalling: () => _setInstalling(true),
      choose: _choose,
      cancellation: cancellation.stream,
      progress: (value) {
        if (identical(_cancellation, cancellation)) {
          installProgress = value;
          _changes.add(null);
        }
      },
    );
    if (!identical(_cancellation, cancellation)) {
      return;
    }
    _setInstalling(false);
    final bootstrapProfile = _drivers.profileFor(bundle, device);
    final host = device.endpoints.first.host;
    var endpoint = bundle.discovery.endpoint(host);
    var software = await _openSession(bundle, endpoint, cancellation);
    if (!identical(_cancellation, cancellation)) {
      return;
    }
    var identified = copyDevice(
      device,
      model: software?.model,
      softwareInformation: software,
    );
    var profile = software == null
        ? bootstrapProfile
        : _drivers.compatibleProfile(bundle, identified);
    if (profile == null) {
      final replacement = await _replaceSession(
        bundle,
        identified,
        cancellation,
      );
      if (!identical(_cancellation, cancellation)) {
        return;
      }
      bundle = replacement.bundle;
      endpoint = replacement.endpoint;
      software = replacement.software ?? software;
      identified = copyDevice(
        identified,
        model: software?.model,
        softwareInformation: software,
      );
      profile = replacement.profile;
    }
    _endpoint = endpoint;
    _bundle = bundle;
    _profile = profile;
    _sessionSoftware = software;
    _device = copyDevice(
      identified,
      metadata: {
        ...device.metadata,
        'managedDriverId': bundle.manifest.identity.id,
        'managedDriverVersion': bundle.manifest.identity.version.toString(),
        'managedDriverProfile': profile.id,
        'managedDriverProfileVersion': profile.version.toString(),
      },
    );
    _setState(DeviceConnectionState.connected);
  }

  Future<
    ({
      DriverBundle bundle,
      Uri endpoint,
      DeviceSoftwareInformation? software,
      DriverCompatibility profile,
    })
  >
  _replaceSession(
    DriverBundle bootstrap,
    RemoteDevice identified,
    StreamController<void> cancellation,
  ) async {
    bool cancelled() => !identical(_cancellation, cancellation);
    final replacement = await _drivers.prepareReplacement(
      bootstrap,
      identified,
      cancelled: cancelled,
      cancellation: cancellation.stream,
    );
    if (replacement == null || cancelled()) {
      throw const RemoteException(
        'driverIncompatible',
        'No available release supports the TV’s reported software.',
      );
    }
    final endpoint = replacement.discovery.endpoint(
      identified.endpoints.first.host,
    );
    final software = await _openSession(
      replacement,
      endpoint,
      cancellation,
      replacing: true,
    );
    if (cancelled()) {
      throw const RemoteException('cancelled', 'Driver connection cancelled.');
    }
    final profile = _drivers.profileFor(
      replacement,
      copyDevice(
        identified,
        model: software?.model,
        softwareInformation: software,
      ),
    );
    final pending = _pendingReplacement;
    if (replacement.requiresPersistentSession && pending?.connected != true) {
      throw const RemoteException(
        'disconnected',
        'The replacement driver lost its connection.',
      );
    }
    final original = _persistent;
    _persistent = pending;
    _pendingReplacement = null;
    await original?.close();
    return (
      bundle: replacement,
      endpoint: endpoint,
      software: software,
      profile: profile,
    );
  }

  Future<DeviceSoftwareInformation?> _openSession(
    DriverBundle bundle,
    Uri endpoint,
    StreamController<void> cancellation, {
    bool replacing = false,
  }) async {
    final connection = _drivers.runtime.connection(
      endpoint: endpoint,
      trustedCertificateDer: device.metadata['trustedCertificateDer'],
    );
    if (!bundle.requiresPersistentSession) {
      await connection.connect(cancellation: cancellation.stream);
      await connection.close();
      return null;
    }
    late final ManagedTvSession session;
    session = ManagedTvSession(
      connection,
      bundle,
      onLost: () {
        if (identical(_cancellation, cancellation) &&
            identical(_persistent, session)) {
          unawaited(disconnect());
        }
      },
    );
    _rememberSession(session, replacing: replacing);
    return session.open(
      credentials: _drivers.credentialScope(bundle, device),
      requestCode: _requestPairingCode,
      feedback: _feedback,
      subscriptionRejected: _rejectedSubscriptions.add,
    );
  }

  void _rememberSession(ManagedTvSession session, {required bool replacing}) {
    if (!replacing) {
      _persistent = session;
      return;
    }
    _pendingReplacement = session;
    _rejectedSubscriptions.clear();
  }

  Future<String?> _requestPairingCode() async {
    final pending = _pairingCode = Completer<String?>();
    _setState(DeviceConnectionState.pairing);
    try {
      return await pending.future;
    } finally {
      if (identical(_pairingCode, pending)) {
        _pairingCode = null;
        _setState(DeviceConnectionState.connecting);
      }
    }
  }

  @override
  Future<bool> submitPairingCode(String code) async {
    final pending = _pairingCode;
    if (pending == null || pending.isCompleted || !_validCode.hasMatch(code)) {
      return false;
    }
    pending.complete(code);
    return true;
  }

  static final _validCode = RegExp(r'^[0-9a-fA-F]{6}$');

  void _feedback(Map<String, Object?> event) {
    switch (event['event']) {
      case 'volume':
        _publishFeedback(_volume, event, DriverTvResponse.volume);
      case 'content':
        _publishFeedback(_content, event, DriverTvResponse.content);
      case 'input':
        _publishFeedback(_inputs, event, (response) {
          return _currentInput = DriverTvResponse.input(response);
        });
    }
  }

  void _publishFeedback<T>(
    StreamController<T> target,
    Map<String, Object?> event,
    T Function(Map<String, Object?>) decode,
  ) {
    try {
      target.add(decode(event));
    } on RemoteException catch (error, trace) {
      target.addError(error, trace);
    }
  }

  Future<DriverMatch?> _choose(List<DriverMatch> alternatives) async {
    final selection = _selection = Completer<DriverMatch?>();
    choices = List.unmodifiable(alternatives);
    _setState(DeviceConnectionState.pairing);
    try {
      return await selection.future;
    } finally {
      if (identical(_selection, selection)) {
        _selection = null;
        choices = const [];
        _setState(DeviceConnectionState.connecting);
      }
    }
  }

  Future<Map<String, Object?>?> _command(
    RemoteCapability capability,
    String id, [
    Map<String, Object> arguments = const {},
  ]) async {
    final cancellation = _cancellation;
    final bundle = _bundle;
    final endpoint = _endpoint;
    if (bundle == null || endpoint == null || cancellation == null) {
      throw const RemoteException('disconnected', 'Connect to the TV first.');
    }
    if (_disabled(capability) ||
        !DriverTvCapabilities.provides(bundle, capability, id)) {
      throw _unavailable;
    }
    final exchange = bundle.exchanges[id];
    final result =
        !bundle.commands.containsKey(id) &&
            exchange?.operation == DriverOperation.webSocketRequest
        ? await _persistent!.request(exchange!, arguments)
        : await _drivers.runtime.execute(
            bundle.commands[id]!,
            endpoint: endpoint,
            arguments: arguments,
            trustedCertificateDer: device.metadata['trustedCertificateDer'],
            cancellation: cancellation.stream,
          );
    if (!identical(_cancellation, cancellation)) {
      throw const RemoteException('cancelled', 'Driver command cancelled.');
    }
    if (result?['ok'] == false) {
      throw const RemoteException(
        'driverRejected',
        'The TV rejected the command.',
      );
    }
    return result;
  }

  Future<T> _read<T>(
    RemoteCapability capability,
    String id,
    T Function(Map<String, Object?>) decode,
  ) async {
    final result = await _command(capability, id);
    if (result == null) {
      throw const RemoteException(
        'driverResponse',
        'The TV returned no response.',
      );
    }
    final decoded = decode(result);
    if (decoded != null) {
      _acknowledge(id);
    }
    return decoded;
  }

  Future<void> _send(
    RemoteCapability capability,
    String id, [
    Map<String, Object> arguments = const {},
  ]) async {
    final result = await _command(capability, id, arguments);
    if (result?['ok'] == true) {
      _acknowledge(id);
    }
  }

  void _acknowledge(String id) {
    if (_acknowledged.add(id)) {
      _changes.add(null);
    }
  }

  bool _has(RemoteCapability capability, String id) {
    final bundle = _bundle;
    return bundle != null &&
        !_disabled(capability) &&
        DriverTvCapabilities.provides(bundle, capability, id);
  }

  void _setInstalling(bool value) {
    if (_installing == value) {
      return;
    }
    _installing = value;
    if (!value) {
      installProgress = null;
    }
    _changes.add(null);
  }

  void _setState(DeviceConnectionState next) {
    state = next;
    _states.add(next);
  }

  @override
  Future<void> disconnect() async {
    final cancellation = _cancellation;
    if (cancellation == null) {
      return;
    }
    _cancellation = null;
    final persistent = _persistent;
    final replacement = _pendingReplacement;
    _persistent = null;
    _pendingReplacement = null;
    final pairing = _pairingCode;
    _pairingCode = null;
    if (pairing != null && !pairing.isCompleted) {
      pairing.complete(null);
    }
    _rejectedSubscriptions.clear();
    _acknowledged.clear();
    final selection = _selection;
    _selection = null;
    choices = const [];
    if (selection != null && !selection.isCompleted) {
      selection.complete(null);
    }
    _setInstalling(false);
    _bundle = null;
    _profile = null;
    _sessionSoftware = null;
    _currentInput = null;
    _reportedApplicationIds = null;
    _inputs.add(null);
    _endpoint = null;
    _setState(DeviceConnectionState.disconnected);
    cancellation.add(null);
    await cancellation.close();
    await Future.wait([
      if (persistent != null) persistent.close(),
      if (replacement != null) replacement.close(),
    ]);
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
    await _volume.close();
    await _content.close();
    await _inputs.close();
  }

  @override
  bool get canWake => _has(RemoteCapability.wake, 'wake');
  @override
  Future<void> wake() => _send(RemoteCapability.wake, 'wake');
  @override
  Future<void> volumeUp() => _send(RemoteCapability.volume, 'volume-up');
  @override
  Future<void> volumeDown() => _send(RemoteCapability.volume, 'volume-down');
  @override
  Future<void> powerOff() => _send(RemoteCapability.power, 'power-off');
  @override
  Future<void> turnOffScreen() =>
      _send(RemoteCapability.screenPower, 'screen-off');
  @override
  Future<void> turnOnScreen() =>
      _send(RemoteCapability.screenPower, 'screen-on');

  @override
  Future<void> setVolume(int volume) {
    RangeError.checkValueInInterval(volume, 0, 100, 'volume');
    return _send(RemoteCapability.absoluteVolume, 'set-volume', {
      'volume': volume,
    });
  }

  @override
  Future<void> setMuted(bool muted) =>
      _send(RemoteCapability.mute, 'set-mute', {'muted': muted});

  @override
  Future<void> toggleMute() async {
    if (_has(RemoteCapability.mute, 'toggle-mute')) {
      return _send(RemoteCapability.mute, 'toggle-mute');
    }
    final volume = await readVolume();
    if (volume.muted == null) {
      throw _unavailable;
    }
    await setMuted(!volume.muted!);
  }

  @override
  Future<VolumeState> readVolume() async {
    final state = await _read(
      RemoteCapability.volumeFeedback,
      'read-volume',
      DriverTvResponse.volume,
    );
    if (!_volume.isClosed) {
      _volume.add(state);
    }
    return state;
  }

  @override
  Stream<VolumeState> watchVolume() => _volume.stream;

  @override
  Future<void> press(NavigationKey key) =>
      _send(RemoteCapability.navigation, 'navigation-${key.name}');
  @override
  Future<void> channelUp() => _send(RemoteCapability.channels, 'channel-up');
  @override
  Future<void> channelDown() =>
      _send(RemoteCapability.channels, 'channel-down');
  @override
  Future<List<DeviceChannel>> channels() => _read(
    _has(RemoteCapability.channelCatalog, 'list-channels')
        ? RemoteCapability.channelCatalog
        : RemoteCapability.channelSelection,
    'list-channels',
    DriverTvResponse.channels,
  );
  @override
  Future<void> selectChannel(String id) =>
      _target(RemoteCapability.channelSelection, 'select-channel', id);

  @override
  Future<void> sendMedia(MediaAction action) {
    final capability = switch (action) {
      MediaAction.next ||
      MediaAction.previous => RemoteCapability.trackNavigation,
      MediaAction.fastForward ||
      MediaAction.rewind => RemoteCapability.playbackScan,
      _ => RemoteCapability.media,
    };
    final id = 'media-${_wireId(action.name)}';
    return _send(
      _has(capability, id) ? capability : RemoteCapability.media,
      id,
    );
  }

  @override
  Future<void> togglePlayback() =>
      _send(RemoteCapability.playbackToggle, 'toggle-playback');
  @override
  Future<bool?> playbackState() => _read(
    RemoteCapability.playbackToggle,
    'read-playback',
    DriverTvResponse.playback,
  );

  @override
  Future<void> movePointer(double dx, double dy) =>
      _pointer('pointer-move', dx, dy);
  @override
  Future<void> scroll(double dx, double dy) =>
      _pointer('pointer-scroll', dx, dy);
  @override
  Future<void> click() => _send(RemoteCapability.pointer, 'pointer-click');

  Future<void> _pointer(String action, double dx, double dy) {
    if (!dx.isFinite || !dy.isFinite || dx.abs() > 10000 || dy.abs() > 10000) {
      throw ArgumentError('Pointer movement is outside the supported range.');
    }
    return _send(RemoteCapability.pointer, action, {'dx': dx, 'dy': dy});
  }

  @override
  Future<void> sendKey(RemoteKey key) {
    final capability = switch (key) {
      RemoteKey.mute => RemoteCapability.mute,
      RemoteKey.source => RemoteCapability.inputs,
      RemoteKey.settings => RemoteCapability.tvSettings,
      RemoteKey.liveTv => RemoteCapability.liveTvKey,
      RemoteKey.captions => RemoteCapability.captionsKey,
      RemoteKey.replay => RemoteCapability.instantReplay,
      _ when key.name.startsWith('digit') => RemoteCapability.numericKeys,
      _ => RemoteCapability.specialKeys,
    };
    return _send(capability, 'key-${_wireId(key.name)}');
  }

  @override
  Future<void> sendText(String text) {
    if (text.length > 2048) {
      throw ArgumentError('Text exceeds the supported length.');
    }
    return _send(RemoteCapability.textInput, 'send-text', {'text': text});
  }

  @override
  Future<void> sendEnter() => _send(RemoteCapability.textInput, 'send-enter');
  @override
  Future<List<DeviceInput>> inputs() =>
      _read(RemoteCapability.inputs, 'list-inputs', DriverTvResponse.inputs);
  @override
  Future<void> selectInput(String id) =>
      _target(RemoteCapability.inputs, 'select-input', id);
  @override
  Future<void> openInputPicker() =>
      _send(RemoteCapability.inputs, 'open-input-picker');
  @override
  DeviceInput? get currentInput => _currentInput;
  @override
  Stream<DeviceInput?> get currentInputChanges => _inputs.stream;

  Future<DeviceInput> readCurrentInput() async {
    final input = await _read(
      RemoteCapability.currentInput,
      'read-input',
      DriverTvResponse.input,
    );
    if (!_inputs.isClosed) {
      _currentInput = input;
      _inputs.add(input);
    }
    return input;
  }

  @override
  Future<List<DeviceApplication>> applications() async {
    final apps = await _read(
      RemoteCapability.applications,
      'list-applications',
      DriverTvResponse.applications,
    );
    _reportedApplicationIds = Set.unmodifiable(apps.map((app) => app.id));
    return apps;
  }

  @override
  Set<String>? get reportedApplicationIds => _reportedApplicationIds;
  @override
  Future<void> launchApplication(String id) =>
      _target(RemoteCapability.applications, 'launch-application', id);
  @override
  Future<String?> currentApplication() async {
    if (_has(RemoteCapability.currentContent, 'read-application')) {
      return _read(
        RemoteCapability.currentContent,
        'read-application',
        DriverTvResponse.application,
      );
    }
    return (await currentContent()).appId;
  }

  @override
  Future<CurrentContent> currentContent() async {
    final content = await _read(
      RemoteCapability.currentContent,
      'read-content',
      DriverTvResponse.content,
    );
    if (!_content.isClosed) {
      _content.add(content);
    }
    return content;
  }

  @override
  Stream<CurrentContent> watchCurrentContent() => _content.stream;
  @override
  Future<List<BluetoothAccessory>> bluetoothAccessories() => _read(
    RemoteCapability.bluetoothAccessories,
    'list-accessories',
    DriverTvResponse.accessories,
  );
  @override
  Future<void> toggleBluetoothAccessory(String id) =>
      _target(RemoteCapability.bluetoothAccessories, 'toggle-accessory', id);
  @override
  Future<void> openAccessorySettings() =>
      _send(RemoteCapability.accessorySettings, 'open-accessory-settings');

  Future<void> _target(RemoteCapability capability, String action, String id) {
    if (id.trim().isEmpty || id.length > 2048) {
      throw ArgumentError('Invalid TV command target.');
    }
    return _send(capability, action, {'target': id});
  }

  static final _uppercase = RegExp(r'[A-Z]');
  static String _wireId(String name) => name.replaceAllMapped(
    _uppercase,
    (match) => '-${match[0]!.toLowerCase()}',
  );

  static const _unavailable = RemoteException(
    'unsupported',
    'The driver does not provide this command.',
  );
}
