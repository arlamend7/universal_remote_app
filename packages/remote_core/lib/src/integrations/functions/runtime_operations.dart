import '../../tv_remote_base.dart';

/// The runtime operation vocabulary that integrations map to engine calls.
///
/// These IDs are generic television actions; nothing here identifies a
/// manufacturer. A mapping key outside this vocabulary is rejected.
abstract final class RuntimeOperations {
  static String navigation(NavigationKey key) => 'navigation-${key.name}';
  static String media(MediaAction action) => 'media-${_kebab(action.name)}';
  static String key(RemoteKey key) => 'key-${_kebab(key.name)}';

  static const volumeUp = 'volume-up';
  static const volumeDown = 'volume-down';
  static const setVolume = 'set-volume';
  static const setMute = 'set-mute';
  static const toggleMute = 'toggle-mute';
  static const readVolume = 'read-volume';
  static const powerOff = 'power-off';
  static const wake = 'wake';
  static const screenOff = 'screen-off';
  static const screenOn = 'screen-on';
  static const channelUp = 'channel-up';
  static const channelDown = 'channel-down';
  static const listChannels = 'list-channels';
  static const selectChannel = 'select-channel';
  static const togglePlayback = 'toggle-playback';
  static const readPlayback = 'read-playback';
  static const pointerMove = 'pointer-move';
  static const pointerScroll = 'pointer-scroll';
  static const pointerClick = 'pointer-click';
  static const sendText = 'send-text';
  static const sendEnter = 'send-enter';
  static const listInputs = 'list-inputs';
  static const selectInput = 'select-input';
  static const openInputPicker = 'open-input-picker';
  static const readInput = 'read-input';
  static const listApplications = 'list-applications';
  static const launchApplication = 'launch-application';
  static const readApplication = 'read-application';
  static const readContent = 'read-content';
  static const listAccessories = 'list-accessories';
  static const toggleAccessory = 'toggle-accessory';
  static const openAccessorySettings = 'open-accessory-settings';
  static const startVoice = 'start-voice';
  static const toggleGameMode = 'toggle-game-mode';
  static const identifySoftware = 'identify-software';
  static const readWakeAddress = 'read-wake-address';
  static const openPointer = 'open-pointer';

  static final Set<String> commands = Set.unmodifiable({
    volumeUp,
    volumeDown,
    setVolume,
    setMute,
    toggleMute,
    readVolume,
    powerOff,
    wake,
    screenOff,
    screenOn,
    for (final key in NavigationKey.values) navigation(key),
    channelUp,
    channelDown,
    listChannels,
    selectChannel,
    for (final action in MediaAction.values) media(action),
    togglePlayback,
    readPlayback,
    pointerMove,
    pointerScroll,
    pointerClick,
    for (final remoteKey in RemoteKey.values) key(remoteKey),
    sendText,
    sendEnter,
    listInputs,
    selectInput,
    openInputPicker,
    readInput,
    listApplications,
    launchApplication,
    readApplication,
    readContent,
    listAccessories,
    toggleAccessory,
    openAccessorySettings,
    startVoice,
    toggleGameMode,
    identifySoftware,
    readWakeAddress,
    openPointer,
  });

  /// State streams a session may keep open while connected.
  static const subscriptions = {'volume', 'content', 'input'};

  static bool isCommand(String id) => commands.contains(id);

  /// Commands plus `subscribe-<state>` streams.
  static bool isMappable(String id) =>
      isCommand(id) ||
      (id.startsWith('subscribe-') &&
          subscriptions.contains(id.substring('subscribe-'.length)));

  static String _kebab(String name) => name.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '-${match[0]!.toLowerCase()}',
  );
}
