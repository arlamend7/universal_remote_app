import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:xml/xml.dart';

import 'roku_app_catalog.dart';

import 'package:remote_driver_runtime/roku_ecp.dart';

import 'roku_serial.dart';
import 'roku_channel_data.dart';

final class RokuController extends TVRemoteBase {
  RokuController(this._device, this.client, {this.bindings});

  @override
  RemoteDevice get device => _device;
  @override
  DeviceSoftwareInformation? get sessionSoftwareInformation =>
      state == DeviceConnectionState.connected
      ? device.softwareInformation
      : null;
  RemoteDevice _device;
  final RokuEcpClient client;
  final DriverBindings? bindings;
  final _states = StreamController<DeviceConnectionState>.broadcast();
  final _inputChanges = StreamController<DeviceInput?>.broadcast();
  DeviceInput? _currentInput;
  final _changes = StreamController<void>.broadcast();
  @override
  Stream<void> get capabilityChanges => _changes.stream;
  final _unavailable = <RemoteCapability>{};
  final _capabilities = <RemoteCapability>{};
  RokuAppCatalog? _catalog;
  bool _isTv = false;
  bool _hasTunerFeedback = false;
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
    for (final capability in _unavailable)
      CapabilityEvidence(
        capability,
        CapabilitySource.driver,
        CapabilityAvailability.unavailable,
      ),
    for (final capability in _capabilities)
      CapabilityEvidence(
        capability,
        CapabilitySource.driver,
        capability == RemoteCapability.currentContent
            ? CapabilityAvailability.verified
            : CapabilityAvailability.known,
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
    final channelList = isTv
        ? await _readChannelCatalog()
        : const <DeviceChannel>[];
    final catalog = await catalogRequest;
    if (generation != _generation) {
      throw const RemoteException(
        'cancelled',
        'The Roku connection was canceled.',
      );
    }
    _serial = serial;
    final version = rokuField(info, 'software-version');
    final model = rokuField(info, 'model-name');
    final modelNumber = rokuField(info, 'model-number');
    final build = rokuField(info, 'software-build');
    final vendor = rokuField(info, 'vendor-name');
    _device = copyDevice(
      device,
      category: isTv ? DeviceCategory.television : DeviceCategory.mediaPlayer,
      model: model,
      softwareInformation: DeviceSoftwareInformation(
        source: DeviceInformationSource.protocolResponse,
        manufacturer: vendor,
        model: model,
        hardwareModel: modelNumber,
        operatingSystem: 'Roku OS',
        operatingSystemVersion: version,
        buildNumber: build,
        identifiedAt: DateTime.now(),
        raw: {
          if (vendor != null) 'vendor-name': vendor,
          if (model != null) 'model-name': model,
          if (modelNumber != null) 'model-number': modelNumber,
          if (version != null) 'software-version': version,
          if (build != null) 'software-build': build,
          if (info.getElement('is-tv') != null) 'is-tv': isTv.toString(),
        },
      ),
      metadata: {
        ...device.metadata,
        if (version != null) 'softwareVersion': version,
      },
    );
    _catalog = catalog;
    _isTv = isTv;
    _hasTunerFeedback = channelList.isNotEmpty;
    _capabilities.addAll({
      RemoteCapability.navigation,
      RemoteCapability.textInput,
      RemoteCapability.playbackToggle,
      RemoteCapability.playbackScan,
      RemoteCapability.instantReplay,
      if (isTv) RemoteCapability.channels,
      if (channelList.isNotEmpty) RemoteCapability.channelCatalog,
      if (_supportsControl(info, 'supports-audio-volume-control', isTv))
        RemoteCapability.mute,
      if (_supportsControl(info, 'supports-audio-volume-control', isTv))
        RemoteCapability.volume,
      if (_supportsControl(info, 'supports-tv-power-control', isTv))
        RemoteCapability.power,
      if (catalog?.apps.isNotEmpty == true) RemoteCapability.applications,
      if (content != null) RemoteCapability.currentContent,
      if (isTv && catalog?.inputs.isNotEmpty == true) ...[
        RemoteCapability.inputs,
        RemoteCapability.currentInput,
      ],
    });
    _device = bindings?.describe(device, null) ?? device;
    _state(DeviceConnectionState.connected);
  }

  bool _supportsControl(XmlElement info, String name, bool defaultValue) =>
      switch (info.getElement(name)?.innerText.trim()) {
        'true' => true,
        'false' => false,
        _ => defaultValue,
      };

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
      return root.name.local == 'apps'
          ? RokuAppCatalog(root, client.endpoint)
          : null;
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
          (error.code == 'permission' || error.code == 'unsupported') &&
          _capabilities.remove(capability)) {
        _unavailable.add(capability);
        _changes.add(null);
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
    _unavailable.clear();
    _catalog = null;
    _isTv = false;
    _hasTunerFeedback = false;
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
    await _changes.close();
    await _inputChanges.close();
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
  Future<bool?> playbackState() async {
    final player = await _optionalQuery('media-player');
    if (player == null || player.name.local != 'player') {
      return null;
    }
    return switch (player.getAttribute('state')) {
      'play' => true,
      'pause' => false,
      _ => null,
    };
  }

  @override
  Future<void> togglePlayback() =>
      _key(RemoteCapability.playbackToggle, 'Play');
  @override
  Future<void> volumeUp() =>
      _managedKey(RemoteCapability.volume, 'volume-up', 'VolumeUp');
  @override
  Future<void> volumeDown() =>
      _managedKey(RemoteCapability.volume, 'volume-down', 'VolumeDown');
  @override
  Future<void> powerOff() =>
      _managedKey(RemoteCapability.power, 'power-off', 'PowerOff');
  Future<void> _managedKey(
    RemoteCapability capability,
    String action,
    String fallback,
  ) => _key(capability, bindings?.select(action, fallback) ?? fallback);

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

  /// Launches an installed app, optionally with a deep link written as
  /// `appId?contentId=…&mediaType=…` (the documented ECP launch parameters).
  @override
  Future<void> launchApplication(String target) {
    final link = _launchLink(target);
    if (link == null || reportedApplicationIds?.contains(link.id) != true) {
      return _unsupported();
    }
    return _command(
      RemoteCapability.applications,
      () => client.launch(link.id, parameters: link.parameters),
    );
  }

  static const _mediaTypes = {
    'series',
    'season',
    'episode',
    'movie',
    'shortFormVideo',
    'tvSpecial',
  };

  ({String id, Map<String, String>? parameters})? _launchLink(String target) {
    final split = target.indexOf('?');
    final id = split < 0 ? target : target.substring(0, split);
    if (id.isEmpty) {
      return null;
    }
    if (split < 0) {
      return (id: id, parameters: null);
    }
    final Map<String, String> query;
    try {
      query = Uri.splitQueryString(target.substring(split + 1));
    } on FormatException {
      return null;
    }
    final contentId = query['contentId'];
    final mediaType = query['mediaType'];
    final valid =
        query.keys.every((key) => key == 'contentId' || key == 'mediaType') &&
        contentId != null &&
        contentId.isNotEmpty &&
        contentId.length < 255 &&
        (mediaType == null || _mediaTypes.contains(mediaType));
    return valid ? (id: id, parameters: query) : null;
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
  bool get canWake => supports(RemoteCapability.power);
  @override
  Future<void> wake() => _key(RemoteCapability.power, 'PowerOn');
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
  Future<void> channelUp() => _key(RemoteCapability.channels, 'ChannelUp');
  @override
  Future<void> channelDown() => _key(RemoteCapability.channels, 'ChannelDown');
  @override
  Future<List<DeviceChannel>> channels() async {
    if (!_isTv || !supports(RemoteCapability.channelCatalog)) {
      return _unsupported();
    }
    return rokuChannels(await client.query('tv-channels'));
  }

  Future<List<DeviceChannel>> _readChannelCatalog() async {
    final root = await _optionalQuery('tv-channels');
    return root == null ? const [] : rokuChannels(root);
  }

  Future<XmlElement?> _optionalQuery(String name) async {
    try {
      return await client.query(name);
    } on RemoteException {
      return null;
    }
  }

  @override
  Future<void> selectChannel(String id) => _unsupported();
  @override
  Future<void> sendMedia(MediaAction action) => switch (action) {
    MediaAction.rewind => _key(RemoteCapability.playbackScan, 'Rev'),
    MediaAction.fastForward => _key(RemoteCapability.playbackScan, 'Fwd'),
    _ => _unsupported(),
  };
  @override
  Future<void> movePointer(double dx, double dy) => _unsupported();
  @override
  Future<void> scroll(double dx, double dy) => _unsupported();
  @override
  Future<void> click() => _unsupported();
  @override
  Future<void> sendKey(RemoteKey key) => switch (key) {
    RemoteKey.mute => _key(RemoteCapability.mute, 'VolumeMute'),
    RemoteKey.replay => _key(RemoteCapability.instantReplay, 'InstantReplay'),
    _ => _unsupported(),
  };
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
    return _readActivity(app?.getAttribute('id') ?? 'roku.home', name);
  }

  Future<CurrentContent> _readActivity(String appId, String name) async {
    if (state != DeviceConnectionState.connected) {
      return CurrentContent(appId: appId, appName: name);
    }
    _rememberInput(appId);
    final tuner = _hasTunerFeedback
        ? await _optionalQuery('tv-active-channel')
        : null;
    final channel = tuner?.getElement('channel');
    if (rokuField(channel, 'active-input') == 'true') {
      return CurrentContent(
        appId: appId,
        appName: name,
        liveTv: true,
        channelNumber: rokuField(channel, 'number'),
        channelName: rokuField(channel, 'name'),
        programTitle: rokuField(channel, 'program-title'),
      );
    }
    final player = await _optionalQuery('media-player');
    final playerApp = player?.getElement('plugin')?.getAttribute('id');
    if (player == null || player.name.local != 'player' || playerApp != appId) {
      return CurrentContent(appId: appId, appName: name);
    }
    return CurrentContent(
      appId: appId,
      appName: name,
      position: rokuMediaTime(player, 'position'),
      duration: rokuMediaTime(player, 'duration'),
    );
  }

  void _rememberInput(String appId) {
    final input = _catalog?.inputs
        .where((candidate) => candidate.id == appId)
        .firstOrNull;
    if (input?.id == _currentInput?.id) {
      return;
    }
    _currentInput = input;
    _inputChanges.add(input);
  }

  @override
  DeviceInput? get currentInput => _currentInput;
  @override
  Stream<DeviceInput?> get currentInputChanges => _inputChanges.stream;
  @override
  Stream<CurrentContent> watchCurrentContent() => const Stream.empty();
}
