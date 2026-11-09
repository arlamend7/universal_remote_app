import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:xml/xml.dart';

import 'roku_app_catalog.dart';
import 'roku_ecp_client.dart';
import 'roku_serial.dart';

final class RokuController extends TVRemoteBase {
  RokuController(this._device, this.client);

  @override
  RemoteDevice get device => _device;
  RemoteDevice _device;
  final RokuEcpClient client;
  final _states = StreamController<DeviceConnectionState>.broadcast();
  final _capabilities = <RemoteCapability>{};
  RokuAppCatalog? _catalog;
  String? _serial;
  int _generation = 0;
  bool _disposed = false;

  @override
  DeviceConnectionState state = DeviceConnectionState.disconnected;
  @override
  Stream<DeviceConnectionState> get connectionStates => _states.stream;

  @override
  String? get reportedDiscoveryIdentity =>
      _serial == null ? null : 'uuid:roku:ecp:$_serial';

  @override
  List<CapabilityEvidence> get evidence => [
    for (final capability in _capabilities)
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
    final generation = ++_generation;
    _state(DeviceConnectionState.connecting);
    try {
      await _identify(generation);
    } catch (_) {
      if (generation == _generation) {
        await disconnect();
      }
      rethrow;
    }
  }

  Future<void> _identify(int generation) async {
    final info = await client.query('device-info');
    final serial = rokuSerial(info);
    if (serial == null) {
      throw const RemoteException(
        'protocol',
        'The device did not report a Roku identity.',
      );
    }
    final expected =
        device.metadata['rokuSerial'] ??
        device.metadata['discoveryIdentity']?.split(':').last;
    if (expected != null && expected.toLowerCase() != serial.toLowerCase()) {
      throw const RemoteException(
        'identity',
        'This address belongs to a different Roku.',
      );
    }
    final isTv = info.getElement('is-tv')?.innerText == 'true';
    final catalogRequest = _loadCatalog();
    final content = await _probeContent();
    final catalog = await catalogRequest;
    if (generation != _generation) {
      throw const RemoteException(
        'cancelled',
        'The Roku connection was canceled.',
      );
    }
    _serial = serial;
    _device = copyDevice(
      device,
      category: isTv ? DeviceCategory.television : DeviceCategory.mediaPlayer,
    );
    _catalog = catalog;
    _capabilities.addAll({
      RemoteCapability.navigation,
      RemoteCapability.textInput,
      RemoteCapability.playbackToggle,
      if (isTv ||
          info.getElement('supports-audio-volume-control')?.innerText == 'true')
        RemoteCapability.volume,
      if (isTv ||
          info.getElement('supports-tv-power-control')?.innerText == 'true')
        RemoteCapability.power,
      if (catalog != null) RemoteCapability.applications,
      if (content != null) RemoteCapability.currentContent,
      if (isTv && catalog?.inputs.isNotEmpty == true) RemoteCapability.inputs,
    });
    _state(DeviceConnectionState.connected);
  }

  Future<CurrentContent?> _probeContent() async {
    try {
      return await currentContent();
    } on RemoteException {
      return null;
    }
  }

  Future<RokuAppCatalog?> _loadCatalog() async {
    try {
      final root = await client.query('apps');
      return root.name.local == 'apps' ? RokuAppCatalog(root) : null;
    } on RemoteException {
      return null;
    }
  }

  Future<void> _command(
    RemoteCapability capability,
    Future<void> Function() send,
  ) async {
    if (state != DeviceConnectionState.connected || !supports(capability)) {
      await _unsupported();
    }
    final generation = _generation;
    try {
      await send();
    } on RemoteException catch (error) {
      if (generation == _generation &&
          (error.code == 'permission' || error.code == 'unsupported')) {
        _capabilities.remove(capability);
      }
      rethrow;
    }
  }

  Future<void> _key(RemoteCapability capability, String name) =>
      _command(capability, () => client.key(name));

  void _state(DeviceConnectionState next) {
    if (state != next) {
      state = next;
      _states.add(next);
    }
  }

  @override
  Future<void> disconnect() async {
    ++_generation;
    _capabilities.clear();
    _catalog = null;
    _state(DeviceConnectionState.disconnected);
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

  @override
  Future<void> press(NavigationKey key) =>
      _key(RemoteCapability.navigation, switch (key) {
        NavigationKey.home => 'Home',
        NavigationKey.back => 'Back',
        NavigationKey.up => 'Up',
        NavigationKey.down => 'Down',
        NavigationKey.left => 'Left',
        NavigationKey.right => 'Right',
        NavigationKey.enter => 'Select',
      });

  @override
  Future<void> togglePlayback() =>
      _key(RemoteCapability.playbackToggle, 'Play');
  @override
  Future<void> volumeUp() => _key(RemoteCapability.volume, 'VolumeUp');
  @override
  Future<void> volumeDown() => _key(RemoteCapability.volume, 'VolumeDown');
  @override
  Future<void> powerOff() => _key(RemoteCapability.power, 'PowerOff');
  @override
  Future<void> sendEnter() => _key(RemoteCapability.textInput, 'Enter');
  @override
  Future<void> sendText(String text) async {
    final runes = text.runes.take(257).toList();
    if (runes.length > 256) {
      throw const RemoteException(
        'text',
        'Send up to 256 characters at a time.',
      );
    }
    final generation = _generation;
    for (final rune in runes) {
      if (generation != _generation) {
        return;
      }
      await _key(
        RemoteCapability.textInput,
        'Lit_${String.fromCharCode(rune)}',
      );
    }
  }

  @override
  Future<List<DeviceApplication>> applications() async =>
      _catalog?.apps.toList(growable: false) ?? const [];
  @override
  Set<String>? get reportedApplicationIds =>
      _catalog?.apps.map((app) => app.id).toSet();
  @override
  Future<void> launchApplication(String id) {
    if (reportedApplicationIds?.contains(id) != true) {
      return _unsupported();
    }
    return _command(RemoteCapability.applications, () => client.launch(id));
  }

  @override
  Future<List<DeviceInput>> inputs() async =>
      _catalog?.inputs.toList(growable: false) ?? const [];
  @override
  Future<void> selectInput(String id) {
    final key = _catalog?.keyForInput(id);
    return key == null ? _unsupported() : _key(RemoteCapability.inputs, key);
  }

  Future<Never> _unsupported() => Future.error(
    const RemoteException(
      'unsupported',
      'This control is unavailable on the Roku.',
    ),
  );

  @override
  bool get canWake => false;
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
  Future<void> channelUp() => _unsupported();
  @override
  Future<void> channelDown() => _unsupported();
  @override
  Future<List<DeviceChannel>> channels() => _unsupported();
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
  Future<String?> currentApplication() async => (await currentContent()).appId;
  @override
  Future<CurrentContent> currentContent() async {
    final root = await client.query('active-app');
    final app = root.getElement('app');
    final name = app?.innerText.trim();
    if (root.name.local != 'active-app' || name == null || name.isEmpty) {
      throw const RemoteException(
        'protocol',
        'Roku did not report the current app.',
      );
    }
    return CurrentContent(
      appId: app?.getAttribute('id') ?? 'roku.home',
      appName: name,
    );
  }

  @override
  Stream<CurrentContent> watchCurrentContent() => const Stream.empty();
}
