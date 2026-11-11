import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';

import '../resolution/driver_match.dart';
import 'managed_driver_service.dart';

/// Maps the supported, named driver commands to the television contract.
final class ManagedTvController extends TVRemoteBase {
  ManagedTvController(this._device, this._drivers);

  @override
  RemoteDevice get device => _device;
  RemoteDevice _device;
  final ManagedDriverService _drivers;
  final _states = StreamController<DeviceConnectionState>.broadcast();
  final _changes = StreamController<void>.broadcast();
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
      if (_provides(bundle, RemoteCapability.volume, [
        'volume-up',
        'volume-down',
      ]))
        const CapabilityEvidence(
          RemoteCapability.volume,
          CapabilitySource.driver,
          CapabilityAvailability.known,
        ),
      if (_provides(bundle, RemoteCapability.power, ['power-off']))
        const CapabilityEvidence(
          RemoteCapability.power,
          CapabilitySource.driver,
          CapabilityAvailability.known,
        ),
    ];
  }

  static bool _provides(
    DriverBundle bundle,
    RemoteCapability capability,
    List<String> commands,
  ) =>
      commands.every(bundle.capabilities[capability]?.contains ?? (_) => false);

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
    final bundle = await _drivers.prepare(
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
    final host = device.endpoints.first.host;
    final endpoint = bundle.discovery.endpoint(host);
    final connection = _drivers.runtime.connection(endpoint: endpoint);
    await connection.connect(cancellation: cancellation.stream);
    await connection.close();
    if (!identical(_cancellation, cancellation)) {
      return;
    }
    _endpoint = endpoint;
    _bundle = bundle;
    _device = copyDevice(
      device,
      metadata: {
        ...device.metadata,
        'managedDriverId': bundle.manifest.identity.id,
      },
    );
    _setState(DeviceConnectionState.connected);
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

  Future<void> _command(String id) async {
    final cancellation = _cancellation;
    final command = _bundle?.commands[id];
    final endpoint = _endpoint;
    if (command == null || endpoint == null || cancellation == null) {
      throw _unavailable;
    }
    await _drivers.runtime.execute(
      command,
      endpoint: endpoint,
      cancellation: cancellation.stream,
    );
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
    final selection = _selection;
    _selection = null;
    choices = const [];
    if (selection != null && !selection.isCompleted) {
      selection.complete(null);
    }
    _setInstalling(false);
    _bundle = null;
    _endpoint = null;
    _setState(DeviceConnectionState.disconnected);
    cancellation.add(null);
    await cancellation.close();
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
  }

  @override
  bool get canWake => false;
  @override
  Future<void> volumeUp() => _command('volume-up');
  @override
  Future<void> volumeDown() => _command('volume-down');
  @override
  Future<void> powerOff() => _command('power-off');

  static const _unavailable = RemoteException(
    'unsupported',
    'The driver does not provide this command.',
  );
  Future<T> _unsupported<T>() => Future.error(_unavailable);

  @override
  Future<void> wake() => _unsupported();
  @override
  Future<void> setVolume(int volume) => _unsupported();
  @override
  Future<void> setMuted(bool muted) => _unsupported();
  @override
  Future<VolumeState> readVolume() => _unsupported();
  @override
  Stream<VolumeState> watchVolume() => const Stream.empty();
  @override
  Future<void> press(NavigationKey key) => _unsupported();
  @override
  Future<void> channelUp() => _unsupported();
  @override
  Future<void> channelDown() => _unsupported();
  @override
  Future<List<DeviceChannel>> channels() async => [];
  @override
  Future<void> selectChannel(String id) => _unsupported();
  @override
  Future<void> sendMedia(MediaAction action) => _unsupported();
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
  Future<List<DeviceInput>> inputs() async => [];
  @override
  Future<void> selectInput(String id) => _unsupported();
  @override
  Future<List<DeviceApplication>> applications() async => [];
  @override
  Future<void> launchApplication(String id) => _unsupported();
  @override
  Future<String?> currentApplication() => _unsupported();
  @override
  Future<CurrentContent> currentContent() => _unsupported();
  @override
  Stream<CurrentContent> watchCurrentContent() => const Stream.empty();
}
