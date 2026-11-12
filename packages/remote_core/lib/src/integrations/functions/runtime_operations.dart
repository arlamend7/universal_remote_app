import '../../tv_remote_base.dart';

/// The runtime operation vocabulary that integrations map to engine calls.
///
/// These IDs are generic television actions; nothing here identifies a
/// manufacturer. A mapping key outside this vocabulary is rejected.
abstract final class RuntimeOperations {
  static String navigation(NavigationKey key) => 'navigation-${key.name}';
  static String media(MediaAction action) => 'media-${_kebab(action.name)}';
  static String key(RemoteKey key) => 'key-${_kebab(key.name)}';

  static final Set<String> commands = Set.unmodifiable({
    'volume-up',
    'volume-down',
    'set-volume',
    'set-mute',
    'toggle-mute',
    'read-volume',
    'power-off',
    'wake',
    'screen-off',
    'screen-on',
    for (final key in NavigationKey.values) navigation(key),
    'channel-up',
    'channel-down',
    'list-channels',
    'select-channel',
    for (final action in MediaAction.values) media(action),
    'toggle-playback',
    'read-playback',
    'pointer-move',
    'pointer-scroll',
    'pointer-click',
    for (final remoteKey in RemoteKey.values) key(remoteKey),
    'send-text',
    'send-enter',
    'list-inputs',
    'select-input',
    'open-input-picker',
    'read-input',
    'list-applications',
    'launch-application',
    'read-application',
    'read-content',
    'list-accessories',
    'toggle-accessory',
    'open-accessory-settings',
    'start-voice',
    'toggle-game-mode',
    'identify-software',
    'read-wake-address',
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
