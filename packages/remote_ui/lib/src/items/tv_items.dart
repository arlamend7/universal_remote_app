import 'package:flutter/material.dart'
    show Icon, IconData, Icons, ScaffoldMessenger, SnackBar, Text;
import 'package:remote_core/remote_core.dart';

import '../devices/tv_remote_device.dart';
import '../elements/remote_action.dart';
import '../elements/remote_collection.dart';
import '../elements/remote_element_context.dart';
import '../elements/remote_info.dart';
import '../elements/remote_reading.dart';
import '../elements/remote_input.dart';
import '../widgets/apps/tv_app_icon.dart';

abstract final class TvItems {
  static final up = RemoteAction<TvRemoteDevice>(
    'nav_up',
    showLabel: false,
    holdable: true,
    builder: (context, remote) => (
      icon: Icons.keyboard_arrow_up,
      label: 'Up',
      enabled: true,
      execute: () => remote.navigate(NavigationKey.up),
    ),
  );
  static final down = RemoteAction<TvRemoteDevice>(
    'nav_down',
    showLabel: false,
    holdable: true,
    builder: (context, remote) => (
      icon: Icons.keyboard_arrow_down,
      label: 'Down',
      enabled: true,
      execute: () => remote.navigate(NavigationKey.down),
    ),
  );
  static final left = RemoteAction<TvRemoteDevice>(
    'nav_left',
    showLabel: false,
    holdable: true,
    builder: (context, remote) => (
      icon: Icons.keyboard_arrow_left,
      label: 'Left',
      enabled: true,
      execute: () => remote.navigate(NavigationKey.left),
    ),
  );
  static final right = RemoteAction<TvRemoteDevice>(
    'nav_right',
    showLabel: false,
    holdable: true,
    builder: (context, remote) => (
      icon: Icons.keyboard_arrow_right,
      label: 'Right',
      enabled: true,
      execute: () => remote.navigate(NavigationKey.right),
    ),
  );
  static final ok = RemoteAction<TvRemoteDevice>(
    'nav_ok',
    showLabel: false,
    holdable: true,
    builder: (context, remote) => (
      icon: Icons.check,
      label: 'OK',
      enabled: true,
      execute: () => remote.navigate(NavigationKey.enter),
    ),
  );
  static final home = RemoteAction<TvRemoteDevice>(
    'nav_home',
    showLabel: false,
    holdable: true,
    builder: (context, remote) => (
      icon: Icons.home_outlined,
      label: 'Home',
      enabled: true,
      execute: () => remote.navigate(NavigationKey.home),
    ),
  );
  static final back = RemoteAction<TvRemoteDevice>(
    'nav_back',
    showLabel: false,
    holdable: true,
    builder: (context, remote) => (
      icon: Icons.undo,
      label: 'Back',
      enabled: true,
      execute: () => remote.navigate(NavigationKey.back),
    ),
  );
  static final play = RemoteAction<TvRemoteDevice>(
    'play',
    builder: (context, remote) => (
      icon: Icons.play_arrow,
      label: 'Play',
      enabled: true,
      execute: () => remote.media(MediaAction.play),
    ),
  );
  static final pause = RemoteAction<TvRemoteDevice>(
    'pause',
    builder: (context, remote) => (
      icon: Icons.pause,
      label: 'Pause',
      enabled: true,
      execute: () => remote.media(MediaAction.pause),
    ),
  );

  /// One button that alternates Play and Pause, showing the next action.
  static final playbackToggle = RemoteAction<TvRemoteDevice>(
    'playback_toggle',
    builder: (_, remote) => (
      icon: Icons.play_circle_outline,
      label: 'Play / Pause',
      enabled: true,
      execute: remote.togglePlayback,
    ),
  );

  static final playPause = RemoteAction<TvRemoteDevice>(
    'play_pause',
    builder: (context, remote) {
      final playing = remote.mediaPlaying;
      return (
        icon: playing ? Icons.pause : Icons.play_arrow,
        label: playing ? 'Pause' : 'Play',
        enabled: true,
        execute: () =>
            remote.media(playing ? MediaAction.pause : MediaAction.play),
      );
    },
  );

  static final stop = RemoteAction<TvRemoteDevice>(
    'stop',
    builder: (context, remote) => (
      icon: Icons.stop,
      label: 'Stop',
      enabled: true,
      execute: () => remote.media(MediaAction.stop),
    ),
  );
  static final rewind = RemoteAction<TvRemoteDevice>(
    'rewind',
    builder: (context, remote) => (
      icon: Icons.fast_rewind,
      label: 'Rewind',
      enabled: true,
      execute: () => remote.media(MediaAction.rewind),
    ),
  );
  static final fastForward = RemoteAction<TvRemoteDevice>(
    'fast_forward',
    builder: (context, remote) => (
      icon: Icons.fast_forward,
      label: 'Fast forward',
      enabled: true,
      execute: () => remote.media(MediaAction.fastForward),
    ),
  );
  static final menu = RemoteAction<TvRemoteDevice>(
    'key_menu',
    builder: (context, remote) => (
      icon: Icons.keyboard_command_key,
      label: 'menu',
      enabled: true,
      execute: () => remote.key(RemoteKey.menu),
    ),
  );
  static final info = RemoteAction<TvRemoteDevice>(
    'key_info',
    builder: (context, remote) => (
      icon: Icons.keyboard_command_key,
      label: 'info',
      enabled: true,
      execute: () => remote.key(RemoteKey.info),
    ),
  );
  static final guide = RemoteAction<TvRemoteDevice>(
    'key_guide',
    builder: (context, remote) => (
      icon: Icons.keyboard_command_key,
      label: 'guide',
      enabled: true,
      execute: () => remote.key(RemoteKey.guide),
    ),
  );
  static final exit = RemoteAction<TvRemoteDevice>(
    'key_exit',
    builder: (context, remote) => (
      icon: Icons.keyboard_command_key,
      label: 'exit',
      enabled: true,
      execute: () => remote.key(RemoteKey.exit),
    ),
  );
  static final red = RemoteAction<TvRemoteDevice>(
    'key_red',
    builder: (context, remote) => (
      icon: Icons.keyboard_command_key,
      label: 'red',
      enabled: true,
      execute: () => remote.key(RemoteKey.red),
    ),
  );
  static final green = RemoteAction<TvRemoteDevice>(
    'key_green',
    builder: (context, remote) => (
      icon: Icons.keyboard_command_key,
      label: 'green',
      enabled: true,
      execute: () => remote.key(RemoteKey.green),
    ),
  );
  static final yellow = RemoteAction<TvRemoteDevice>(
    'key_yellow',
    builder: (context, remote) => (
      icon: Icons.keyboard_command_key,
      label: 'yellow',
      enabled: true,
      execute: () => remote.key(RemoteKey.yellow),
    ),
  );
  static final blue = RemoteAction<TvRemoteDevice>(
    'key_blue',
    builder: (context, remote) => (
      icon: Icons.keyboard_command_key,
      label: 'blue',
      enabled: true,
      execute: () => remote.key(RemoteKey.blue),
    ),
  );
  static final keyDigit1 = RemoteAction<TvRemoteDevice>(
    'key_digit1',
    builder: (context, remote) => (
      icon: null,
      label: '1',
      enabled: true,
      execute: () => remote.key(RemoteKey.digit1),
    ),
  );
  static final keyDigit2 = RemoteAction<TvRemoteDevice>(
    'key_digit2',
    builder: (context, remote) => (
      icon: null,
      label: '2',
      enabled: true,
      execute: () => remote.key(RemoteKey.digit2),
    ),
  );
  static final keyDigit3 = RemoteAction<TvRemoteDevice>(
    'key_digit3',
    builder: (context, remote) => (
      icon: null,
      label: '3',
      enabled: true,
      execute: () => remote.key(RemoteKey.digit3),
    ),
  );
  static final keyDigit4 = RemoteAction<TvRemoteDevice>(
    'key_digit4',
    builder: (context, remote) => (
      icon: null,
      label: '4',
      enabled: true,
      execute: () => remote.key(RemoteKey.digit4),
    ),
  );
  static final keyDigit5 = RemoteAction<TvRemoteDevice>(
    'key_digit5',
    builder: (context, remote) => (
      icon: null,
      label: '5',
      enabled: true,
      execute: () => remote.key(RemoteKey.digit5),
    ),
  );
  static final keyDigit6 = RemoteAction<TvRemoteDevice>(
    'key_digit6',
    builder: (context, remote) => (
      icon: null,
      label: '6',
      enabled: true,
      execute: () => remote.key(RemoteKey.digit6),
    ),
  );
  static final keyDigit7 = RemoteAction<TvRemoteDevice>(
    'key_digit7',
    builder: (context, remote) => (
      icon: null,
      label: '7',
      enabled: true,
      execute: () => remote.key(RemoteKey.digit7),
    ),
  );
  static final keyDigit8 = RemoteAction<TvRemoteDevice>(
    'key_digit8',
    builder: (context, remote) => (
      icon: null,
      label: '8',
      enabled: true,
      execute: () => remote.key(RemoteKey.digit8),
    ),
  );
  static final keyDigit9 = RemoteAction<TvRemoteDevice>(
    'key_digit9',
    builder: (context, remote) => (
      icon: null,
      label: '9',
      enabled: true,
      execute: () => remote.key(RemoteKey.digit9),
    ),
  );
  static final keyDash = RemoteAction<TvRemoteDevice>(
    'key_dash',
    builder: (context, remote) => (
      icon: null,
      label: '−',
      enabled: true,
      execute: () => remote.key(RemoteKey.dash),
    ),
  );
  static final keyDigit0 = RemoteAction<TvRemoteDevice>(
    'key_digit0',
    builder: (context, remote) => (
      icon: null,
      label: '0',
      enabled: true,
      execute: () => remote.key(RemoteKey.digit0),
    ),
  );
  static final keyEnter = RemoteAction<TvRemoteDevice>(
    'key_enter',
    builder: (context, remote) => (
      icon: null,
      label: 'Enter',
      enabled: true,
      execute: () => remote.key(RemoteKey.enter),
    ),
  );
  static final keypad = [
    keyDigit1,
    keyDigit2,
    keyDigit3,
    keyDigit4,
    keyDigit5,
    keyDigit6,
    keyDigit7,
    keyDigit8,
    keyDigit9,
    keyDash,
    keyDigit0,
    keyEnter,
  ];
  static final configuredApp = RemoteAction<TvRemoteDevice>(
    'configured_app',
    builder: (context, remote) {
      final target = context.settings['appTarget']?.trim() ?? '';
      return (
        icon: Icons.launch,
        label: 'Launch app',
        enabled: target.isNotEmpty,
        execute: () => remote.launchShortcut(target),
      );
    },
  );

  static final inputPicker = _remoteKey(
    'input_picker',
    'Input picker',
    Icons.input,
    RemoteKey.source,
  );
  static final settings = _remoteKey(
    'tv_settings',
    'Open TV settings',
    Icons.settings,
    RemoteKey.settings,
  );
  static final replay = _remoteKey(
    'instant_replay',
    'Instant replay',
    Icons.replay,
    RemoteKey.replay,
  );

  static RemoteAction<TvRemoteDevice> _remoteKey(
    String id,
    String label,
    IconData icon,
    RemoteKey key,
  ) => RemoteAction<TvRemoteDevice>(
    id,
    builder: (context, remote) => (
      icon: icon,
      label: label,
      enabled: true,
      execute: () async {
        await remote.key(key);
        if (key == RemoteKey.source || key == RemoteKey.settings) {
          _confirmSent(context);
        }
      },
    ),
  );

  /// These keys give no feedback on the TV's state, so say the command left.
  static void _confirmSent(RemoteElementContext context) {
    final screen = context.buildContext;
    if (screen == null || !screen.mounted) {
      return;
    }
    ScaffoldMessenger.maybeOf(screen)?.showSnackBar(
      const SnackBar(
        content: Text('Command sent. Check the TV for a response.'),
      ),
    );
  }

  static final muteToggle = RemoteAction<TvRemoteDevice>(
    'mute_toggle',
    builder: (context, remote) {
      final muted = context.remote.volume?.muted;
      return (
        icon: muted == true
            ? Icons.volume_up_outlined
            : Icons.volume_off_outlined,
        label: muted == true ? 'Unmute' : 'Mute',
        enabled: context.remote.supports(RemoteCapability.mute),
        execute: () async {
          await remote.mute(null);
          if (muted == null) {
            _confirmSent(context);
          }
        },
      );
    },
  );
  static final muteOn = RemoteAction<TvRemoteDevice>(
    'mute_on',
    builder: (context, remote) => (
      icon: Icons.volume_off_outlined,
      label: 'Mute',
      enabled: true,
      execute: () => remote.mute(true),
    ),
  );
  static final muteOff = RemoteAction<TvRemoteDevice>(
    'mute_off',
    builder: (context, remote) => (
      icon: Icons.volume_up_outlined,
      label: 'Unmute',
      enabled: true,
      execute: () => remote.mute(false),
    ),
  );
  static final voice = RemoteAction<TvRemoteDevice>(
    'voice',
    builder: (context, remote) => (
      icon: Icons.mic_none,
      label: 'Voice',
      enabled: true,
      execute: () => remote.startVoiceControl(),
    ),
  );
  static final gameMode = RemoteAction<TvRemoteDevice>(
    'game_mode',
    builder: (context, remote) => (
      icon: Icons.sports_esports_outlined,
      label: 'Game mode',
      enabled: true,
      execute: () => remote.toggleGameMode(),
    ),
  );
  static final watch = RemoteAction<TvRemoteDevice>(
    'watch_companion',
    builder: (context, remote) => (
      icon: Icons.watch_outlined,
      label: 'Watch companion',
      enabled: true,
      execute: () => remote.syncWatchCompanion(),
    ),
  );
  static final pointerClick = RemoteAction<TvRemoteDevice>(
    'pointer_click',
    builder: (context, remote) => (
      icon: Icons.mouse_outlined,
      label: 'Click',
      enabled: true,
      execute: () => remote.click(),
    ),
  );
  static final volumeUp = RemoteAction<TvRemoteDevice>(
    'volume_up',
    showLabel: false,
    holdable: true,
    builder: (context, remote) => (
      icon: Icons.add,
      label: 'Louder',
      enabled: true,
      execute: () => remote.volumeUp(),
    ),
  );
  static final volumeDown = RemoteAction<TvRemoteDevice>(
    'volume_down',
    showLabel: false,
    holdable: true,
    builder: (context, remote) => (
      icon: Icons.remove,
      label: 'Lower',
      enabled: true,
      execute: () => remote.volumeDown(),
    ),
  );
  static final volumePreset = RemoteAction<TvRemoteDevice>(
    'volume_preset',
    builder: (context, remote) => (
      icon: Icons.volume_up_outlined,
      label:
          context.settings['label'] ??
          'Volume ${context.settings['value'] ?? '15'}',
      enabled: true,
      execute: () => remote.setVolume(
        (int.tryParse(context.settings['value'] ?? '')?.clamp(0, 100) ?? 15)
            .toDouble(),
      ),
    ),
  );
  static final channelUp = RemoteAction<TvRemoteDevice>(
    'channel_up',
    showLabel: false,
    holdable: true,
    builder: (context, remote) => (
      icon: Icons.add,
      label: 'Next channel',
      enabled: true,
      execute: remote.channelUp,
    ),
  );
  static final channelDown = RemoteAction<TvRemoteDevice>(
    'channel_down',
    showLabel: false,
    holdable: true,
    builder: (context, remote) => (
      icon: Icons.remove,
      label: 'Previous channel',
      enabled: true,
      execute: remote.channelDown,
    ),
  );

  static final touchpad =
      RemoteInput<TvRemoteDevice, ({double x, double y, bool scroll})>(
        'touchpad',
        icon: (_) => Icons.touch_app_outlined,
        commit: (remote, motion) =>
            remote.move(motion.x, motion.y, scroll: motion.scroll),
      );
  static final keyboard =
      RemoteInput<TvRemoteDevice, ({String text, bool submit})>(
        'keyboard',
        icon: (_) => Icons.keyboard_outlined,
        slots: 4,
        commit: (remote, entry) =>
            remote.sendText(entry.text, submit: entry.submit),
      );
  static final activity = RemoteInfo<TvRemoteDevice>(
    'current_activity',
    hiddenWhenOffline: true,
    icon: (_) => Icons.live_tv,
    read: (context) {
      final remote = context.remote;
      final content = remote.content;
      return RemoteReading(
        remote.contentTitle,
        subtitle: remote.contentSubtitle,
        leading: content == null
            ? null
            : content.isLiveTv
            ? const Icon(Icons.live_tv_outlined, size: 22)
            : TvAppIcon(
                appId: content.appId,
                name: remote.contentTitle,
                size: 24,
              ),
      );
    },
  );
  static final app = RemoteInfo<TvRemoteDevice>(
    'current_app',
    hiddenWhenOffline: true,
    icon: (_) => Icons.live_tv,
    read: (context) {
      final reading = activity.read(context);
      return RemoteReading(reading.title, leading: reading.leading);
    },
  );
  static RemoteReading _inputReading(DeviceInput? input) =>
      RemoteReading(input?.name ?? 'Current input unavailable');

  static final channelNumber = RemoteInfo<TvRemoteDevice>(
    'channel_number',
    icon: (_) => Icons.live_tv,
    read: (context) =>
        RemoteReading(context.remote.content?.channelNumber ?? '—'),
  );
  static final channelName = RemoteInfo<TvRemoteDevice>(
    'channel_name',
    icon: (_) => Icons.live_tv,
    read: (context) => RemoteReading(
      context.remote.content?.channelName ?? 'Channel unavailable',
    ),
  );
  static final currentInput = RemoteInfo<TvRemoteDevice>(
    'current_input',
    slots: 2,
    icon: (_) => Icons.input,
    watch: (context) => context.remote.connection
        .tvWith(RemoteCapability.currentInput)
        ?.currentInputChanges
        .map(_inputReading),
    read: (context) => _inputReading(context.remote.currentInput),
  );
  static final inputs = RemoteCollection<TvRemoteDevice, DeviceInput>(
    'pinned_inputs',
    title: 'Inputs',
    icon: (_) => Icons.input,
    load: (remote) => remote.installedInputs(),
    entryId: (input) => input.id,
    entryName: (input) => input.name,
    fromOption: DeviceInput.new,
    sample: (data) => data.inputs,
    onSelected: (remote, input) => remote.input(input.id),
  );
  static final channels = RemoteCollection<TvRemoteDevice, DeviceChannel>(
    'pinned_channels',
    title: 'Channels',
    icon: (_) => Icons.live_tv,
    load: (remote) => remote.installedChannels(),
    entryId: (channel) => channel.id,
    entryName: (channel) => '${channel.number} ${channel.name}'.trim(),
    fromOption: (id, name) => DeviceChannel(id, name, ''),
    sample: (data) => data.channels,
    onSelected: (remote, channel) => remote.channel(channel.id),
  );
  static final channelCatalog = RemoteCollection<TvRemoteDevice, DeviceChannel>(
    'channel_catalog',
    title: 'Reported channels',
    icon: (_) => Icons.live_tv,
    load: (remote) => remote.installedChannels(),
    entryId: (channel) => channel.id,
    entryName: (channel) => '${channel.number} ${channel.name}'.trim(),
    fromOption: (id, name) => DeviceChannel(id, name, ''),
    sample: (data) => data.channels,
    onSelected: (_, _) async {},
    readOnly: true,
  );
  static final volume = RemoteInfo<TvRemoteDevice>(
    'current_volume',
    icon: (_) => Icons.volume_up_outlined,
    read: (context) {
      final level = context.remote.volume?.volume;
      return RemoteReading(
        level == null ? '—' : '$level',
        semanticsLabel: level == null
            ? 'Volume unavailable'
            : 'Volume $level percent',
      );
    },
  );
  static final volumeSlider = RemoteInput<TvRemoteDevice, double>(
    'volume_slider',
    icon: (_) => Icons.tune,
    slots: 2,
    current: (context) => context.remote.volume?.volume.toDouble(),
    preview: (remote, value) => remote.previewVolume(value),
    commit: (remote, value) => remote.setVolume(value),
  );
  static final accessories = RemoteCollection<TvRemoteDevice, BluetoothAccessory>(
    'bluetooth_accessories',
    title: 'Bluetooth devices',
    icon: (_) => Icons.bluetooth,
    load: (remote) => remote.bluetoothAccessories(),
    entryId: (accessory) => accessory.id,
    entryName: (accessory) => accessory.name,
    choiceName: (accessory) =>
        '${accessory.name} · ${accessory.connected ? 'Disconnect' : 'Connect'}',
    fromOption: BluetoothAccessory.new,
    sample: (_) => [('sample-soundbar', 'Soundbar')],
    onSelected: (remote, accessory) =>
        remote.toggleBluetoothAccessory(accessory.id),
  );

  static final applications =
      RemoteCollection<TvRemoteDevice, DeviceApplication>(
        'pinned_apps',
        title: 'Apps',
        icon: (_) => Icons.apps,
        trackedByDevice: true,
        artwork: (app) => app.artwork,
        leading: (id, name) => TvAppIcon(appId: id, name: name),
        load: (remote) => remote.installedApps(),
        entryId: (app) => app.id,
        entryName: (app) => app.name,
        fromOption: DeviceApplication.new,
        sample: (data) => data.applications,
        onSelected: (remote, app) => remote.launchApp(app),
      );
}
