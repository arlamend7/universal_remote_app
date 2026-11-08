import 'package:remote_lg_webos/src/capabilities/applications/lg_application_controller.dart';
import 'package:remote_lg_webos/src/capabilities/channels/lg_channel_selection_controller.dart';
import 'package:remote_lg_webos/src/capabilities/content/lg_current_content_controller.dart';
import 'package:remote_lg_webos/src/capabilities/inputs/lg_input_controller.dart';
import 'package:remote_lg_webos/src/capabilities/power/lg_power_controller.dart';
import 'package:remote_lg_webos/src/capabilities/text/lg_text_controller.dart';
import 'package:remote_lg_webos/src/capabilities/volume/lg_volume_controller.dart';
import 'package:remote_lg_webos/src/capabilities/services/lg_capability_registry.dart';
import 'package:remote_lg_webos/src/capabilities/power/lg_wake_address_reader.dart';
import 'package:remote_lg_webos/src/capabilities/services/lg_capability_resolver.dart';
import 'package:remote_lg_webos/src/commands/services/lg_command_channel.dart';
import 'package:remote_lg_webos/src/connection/functions/lg_connection_error.dart';
import 'package:remote_lg_webos/src/pointer/services/lg_pointer_connection.dart';

import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_lg_webos/src/connection/models/lg_connection_options.dart';
import 'package:remote_lg_webos/src/pairing/constants/default_lg_manifest.dart';
import 'package:remote_lg_webos/src/protocol/services/ssap_client.dart';
import 'package:remote_network/remote_network.dart';

final class LgDeviceController extends TVRemoteBase
    implements DeviceWakeAddressSource {
  LgDeviceController({
    required this.device,
    required this.credentials,
    required this.connector,
    this.options = const LgConnectionOptions(),
    this.registrationManifest = defaultLgManifest,
    this.pairingTimeout = const Duration(seconds: 45),
    this.requestTimeout = const Duration(seconds: 8),
  });
  @override
  final RemoteDevice device;
  final CredentialStore credentials;
  final TransportConnector connector;
  final LgConnectionOptions options;
  final Map<String, Object?> registrationManifest;
  final Duration pairingTimeout;
  final Duration requestTimeout;
  final _states = StreamController<DeviceConnectionState>.broadcast();
  final _capabilities = LgCapabilityRegistry();
  late final _commands = LgCommandChannel(onUnavailable: _disable);
  late final _pointer = LgPointerConnection(
    connector: connector,
    onUnavailable: _pointerUnavailable,
  );
  SsapClient? _client;
  StreamSubscription<void>? _lost;
  Future<void>? _connecting;
  int _generation = 0;
  bool _disposed = false;
  bool _wanted = false;
  Timer? _retry;
  int _retryCount = 0;
  @override
  DeviceConnectionState state = DeviceConnectionState.disconnected;
  @override
  Stream<DeviceConnectionState> get connectionStates => _states.stream;
  @override
  List<CapabilityEvidence> get evidence => _capabilities.evidence;

  /// The session-local controller for [kind], or a presentation-safe failure.
  T _use<T extends Object>(RemoteCapability kind) {
    final controller = _capabilities.controller<T>(kind);
    if (controller != null) {
      return controller;
    }
    throw RemoteException(
      'unavailable',
      'This control is unavailable on the connected TV (${kind.name}).',
    );
  }

  LgVolumeController get _volume => _use(RemoteCapability.volume);
  LgPointerConnection get _navigation => _use(RemoteCapability.navigation);
  LgCommandChannel get _channelKeys => _use(RemoteCapability.channels);
  LgChannelSelectionController get _channelList =>
      _use(RemoteCapability.channelSelection);
  LgCommandChannel get _media => _use(RemoteCapability.media);
  LgPointerConnection get _pointerKeys => _use(RemoteCapability.pointer);
  LgTextController get _text => _use(RemoteCapability.textInput);
  LgInputController get _inputs => _use(RemoteCapability.inputs);
  LgApplicationController get _apps => _use(RemoteCapability.applications);
  LgCurrentContentController get _content =>
      _use(RemoteCapability.currentContent);
  LgPowerController? get _power =>
      _capabilities.controller<LgPowerController>(RemoteCapability.power);

  @override
  bool get canWake => _power?.canWake ?? false;
  @override
  Future<void> powerOff() =>
      _use<LgPowerController>(RemoteCapability.power).powerOff();
  @override
  Future<void> wake() => _use<LgPowerController>(RemoteCapability.power).wake();

  @override
  Future<void> volumeUp() => _volume.volumeUp();
  @override
  Future<void> volumeDown() => _volume.volumeDown();
  @override
  Future<void> setVolume(int volume) => _volume.setVolume(volume);
  @override
  Future<void> setMuted(bool muted) => _volume.setMuted(muted);
  @override
  Future<VolumeState> readVolume() => _volume.readVolume();
  @override
  Stream<VolumeState> watchVolume() => _volume.watchVolume();
  @override
  Future<void> press(NavigationKey key) async => _navigation.press(key);
  @override
  Future<void> channelUp() async {
    await _channelKeys.send(RemoteCapability.channels, 'tv/channelUp');
  }

  @override
  Future<void> channelDown() async {
    await _channelKeys.send(RemoteCapability.channels, 'tv/channelDown');
  }

  @override
  Future<List<DeviceChannel>> channels() => _channelList.channels();
  @override
  Future<void> selectChannel(String id) => _channelList.selectChannel(id);
  @override
  Future<void> sendMedia(MediaAction action) async {
    await _media.send(RemoteCapability.media, 'media.controls/${action.name}');
  }

  @override
  Future<void> movePointer(double dx, double dy) async =>
      _pointerKeys.motion('move', dx, dy);
  @override
  Future<void> scroll(double dx, double dy) async =>
      _pointerKeys.motion('scroll', dx, dy);
  @override
  Future<void> click() async => _pointerKeys.click();
  @override
  Future<void> sendKey(RemoteKey key) async => _pointerKeys.specialKey(key);
  @override
  Future<void> sendText(String text) => _text.sendText(text);
  @override
  Future<void> sendEnter() => _text.enter();
  @override
  Future<List<DeviceInput>> inputs() => _inputs.inputs();
  @override
  Future<void> selectInput(String id) => _inputs.selectInput(id);
  @override
  Future<List<DeviceApplication>> applications() => _apps.applications();
  @override
  Future<void> openAccessorySettings() =>
      _use<LgApplicationController>(RemoteCapability.accessorySettings)
          .openAccessorySettings();
  @override
  Future<void> launchApplication(String id) => _apps.launch(id);
  @override
  Future<String?> currentApplication() => _apps.currentApplication();
  @override
  Set<String>? get reportedApplicationIds => _capabilities
      .controller<LgApplicationController>(RemoteCapability.applications)
      ?.reportedApplicationIds;
  @override
  Future<CurrentContent> currentContent() => _content.currentContent();
  @override
  Stream<CurrentContent> watchCurrentContent() =>
      _content.watchCurrentContent();

  @override
  Future<DeviceWakeAddress?> readWakeAddress() async {
    final client = _client;
    final host = device.endpoints.firstOrNull?.host;
    if (state != DeviceConnectionState.connected ||
        client == null ||
        host == null) {
      return null;
    }
    return LgWakeAddressReader(client).read(host);
  }

  void _setState(DeviceConnectionState next) {
    state = next;
    if (!_states.isClosed) {
      _states.add(next);
    }
  }

  @override
  Future<void> connect() {
    if (_disposed) {
      return Future.error(
        const RemoteException(
          'disposed',
          'This device session has been disposed.',
        ),
      );
    }
    if (state == DeviceConnectionState.connected) {
      return Future.value();
    }
    if (_connecting != null) {
      return _connecting!;
    }
    _wanted = true;
    _retry?.cancel();
    final operation = _connect();
    _connecting = operation;
    // Clear the lock on both paths without introducing an unhandled future.
    unawaited(
      operation.then(
        (_) {
          _connecting = null;
        },
        onError: (Object _, StackTrace __) {
          _connecting = null;
        },
      ),
    );
    return operation;
  }

  Future<void> _connect() async {
    final generation = ++_generation;
    _setState(DeviceConnectionState.connecting);
    _capabilities.clear();
    SsapClient? client;
    String? savedKey;
    try {
      final endpoint = _endpoint();
      client = await _openClient(endpoint, generation);
      savedKey = await credentials.read(device.id);
      _requireCurrent(generation);
      await _authorize(client, savedKey, generation);
      await _finishConnection(client, generation);
    } catch (error) {
      throw await _connectionFailed(error, savedKey, client, generation);
    }
  }

  Uri _endpoint() {
    if (device.endpoints.isEmpty) {
      throw const RemoteException(
        'endpoint',
        'No TV network endpoint is configured.',
      );
    }
    final endpoint = device.endpoints.first;
    if (endpoint.scheme == 'ws' && !options.allowInsecure) {
      throw const RemoteException(
        'insecure',
        'Legacy unencrypted transport requires explicit permission.',
      );
    }
    return endpoint;
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _requireCurrent(int generation) {
    if (_isCurrent(generation)) {
      return;
    }
    throw const RemoteException('cancelled', 'Connection was cancelled.');
  }

  Future<SsapClient> _openClient(Uri endpoint, int generation) async {
    final transport = await connector(endpoint);
    if (!_isCurrent(generation)) {
      await transport.close();
      _requireCurrent(generation);
    }
    final client = SsapClient(transport, requestTimeout: requestTimeout);
    _client = client;
    return client;
  }

  Future<void> _authorize(
    SsapClient client,
    String? savedKey,
    int generation,
  ) async {
    _setState(DeviceConnectionState.pairing);
    final key = await client.register(
      clientKey: savedKey,
      timeout: pairingTimeout,
      manifest: registrationManifest,
    );
    _requireCurrent(generation);
    await credentials.write(device.id, key);
    _requireCurrent(generation);
    _commands.attach(client);
  }

  Future<void> _finishConnection(SsapClient client, int generation) async {
    await _resolve(client, generation);
    _requireCurrent(generation);
    if (client.isClosed) {
      throw const RemoteException(
        'disconnected',
        'The TV disconnected during capability checks.',
      );
    }
    _lost = client.disconnected.listen((_) => _sessionLost(generation));
    _retryCount = 0;
    _setState(DeviceConnectionState.connected);
  }

  void _sessionLost(int generation) {
    if (!_isCurrent(generation)) {
      return;
    }
    unawaited(_connectionLost());
  }

  Future<RemoteException> _connectionFailed(
    Object error,
    String? savedKey,
    SsapClient? client,
    int generation,
  ) async {
    try {
      return await _pairingFailure(error, savedKey);
    } finally {
      await _closeFailedClient(client, generation);
    }
  }

  Future<void> _closeFailedClient(SsapClient? client, int generation) async {
    await client?.close();
    if (generation != _generation) {
      return;
    }
    _client = null;
    _commands.detach();
    _capabilities.clear();
    await _closePointer();
    _setState(DeviceConnectionState.disconnected);
  }

  Future<RemoteException> _pairingFailure(
    Object error,
    String? savedKey,
  ) async {
    final failure = lgConnectionError(error);
    if (failure.code != 'pairingRejected' || savedKey == null) {
      return failure;
    }
    _wanted = false;
    await credentials.delete(device.id);
    return const RemoteException(
      'revokedKey',
      'The saved authorization was rejected. Pair again and approve on the TV.',
    );
  }

  Future<void> _resolve(SsapClient client, int generation) async {
    final resolver = LgCapabilityResolver(
      commands: _commands,
      pointer: _pointer,
      registry: _capabilities,
      client: client,
      endpoint: device.endpoints.first,
      options: options,
      isCurrent: () => !_disposed && generation == _generation,
    );
    await resolver.resolve();
  }

  void _pointerUnavailable() {
    _disable(RemoteCapability.navigation);
    _disable(RemoteCapability.pointer);
  }

  void _disable(RemoteCapability capability) {
    _capabilities.disable(
      capability,
      reason: 'The TV rejected or disconnected this control.',
    );
    if (state != DeviceConnectionState.connected) {
      return;
    }
    _setState(state);
  }

  Future<void> _closePointer() => _pointer.close();

  Future<void> _connectionLost() async {
    final generation = _generation;
    final lost = _lost;
    final client = _client;
    _lost = null;
    _client = null;
    _commands.detach();
    _capabilities.clear();
    _setState(DeviceConnectionState.disconnected);
    await _closePointer();
    await lost?.cancel();
    await client?.close();
    if (generation != _generation ||
        !_wanted ||
        _disposed ||
        _retryCount >= 3) {
      return;
    }
    final attempt = ++_retryCount;
    _setState(DeviceConnectionState.reconnecting);
    _retry = Timer(Duration(seconds: 1 << (attempt - 1)), _retryConnection);
  }

  Future<void> _retryConnection() async {
    if (!_wanted || _disposed) {
      return;
    }
    try {
      await connect();
    } catch (_) {
      _retryFailed();
    }
  }

  void _retryFailed() {
    if (!_wanted || _disposed) {
      return;
    }
    unawaited(_connectionLost());
  }

  @override
  Future<void> disconnect() async {
    _wanted = false;
    ++_generation;
    _retry?.cancel();
    await _lost?.cancel();
    _lost = null;
    final client = _client;
    _client = null;
    _commands.detach();
    _capabilities.clear();
    await _closePointer();
    await client?.close();
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
}
