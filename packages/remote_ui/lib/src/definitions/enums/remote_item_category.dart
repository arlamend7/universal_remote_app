/// What kind of control a definition is. Categories marked [alternatives]
/// hold different looks of one control (a volume rocker, slider or dial), so
/// the editor offers their members as styles of each other; every other
/// category only groups unrelated controls.
enum RemoteItemCategory {
  apps('apps'),
  inputs('inputs'),
  channels('channels'),
  audio('audio'),
  navigation('navigation'),
  keypad('numeric keypad'),
  keys('keys', alternatives: true),
  media('media', alternatives: true),
  information('information'),
  utilities('utilities'),
  climate('climate'),
  groups('groups'),
  volume('volume audio', alternatives: true),
  mute('mute', alternatives: true),
  channelArrows('channel arrows', alternatives: true),
  favouriteChannels('channels', alternatives: true),
  directionPad('directional pad arrows ok', alternatives: true),
  pinnedApps('apps', alternatives: true),
  pinnedInputs('inputs', alternatives: true),
  activity('activity', alternatives: true);

  const RemoteItemCategory(this.label, {this.alternatives = false});

  /// Words for the catalog search and for "Choose …" prompts.
  final String label;
  final bool alternatives;
}
