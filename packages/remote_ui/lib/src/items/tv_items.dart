import 'package:flutter/material.dart' show Icon, IconData, Icons;
import 'package:remote_core/remote_core.dart';

import '../rendering/viewmodels/grid_remote_viewmodel.dart';
import '../elements/remote_action.dart';
import '../elements/remote_collection.dart';
import '../elements/remote_info.dart';
import '../elements/remote_reading.dart';
import '../elements/remote_input.dart';
import '../widgets/apps/tv_app_icon.dart';
import '../widgets/dialogs/show_command_sent.dart';

abstract final class TvItems {
  static final up = RemoteAction<GridRemoteViewModel>(
    'nav_up',
    showLabel: false,
    holdable: true,
    builder: (context, remote) => (
      icon: Icons.keyboard_arrow_up,
      label: 'Up',
      enabled: true,
      execute: () => remote.runTv(
        RemoteCapability.navigation,
        (tv) => tv.press(NavigationKey.up),
      ),
    ),
  );
  static final down = RemoteAction<GridRemoteViewModel>(
    'nav_down',
    showLabel: false,
    holdable: true,
    builder: (context, remote) => (
      icon: Icons.keyboard_arrow_down,
      label: 'Down',
      enabled: true,
      execute: () => remote.runTv(
        RemoteCapability.navigation,
        (tv) => tv.press(NavigationKey.down),
      ),
    ),
  );
  static final left = RemoteAction<GridRemoteViewModel>(
    'nav_left',
    showLabel: false,
    holdable: true,
    builder: (context, remote) => (
      icon: Icons.keyboard_arrow_left,
      label: 'Left',
      enabled: true,
      execute: () => remote.runTv(
        RemoteCapability.navigation,
        (tv) => tv.press(NavigationKey.left),
      ),
    ),
  );
  static final right = RemoteAction<GridRemoteViewModel>(
    'nav_right',
    showLabel: false,
    holdable: true,
    builder: (context, remote) => (
      icon: Icons.keyboard_arrow_right,
      label: 'Right',
      enabled: true,
      execute: () => remote.runTv(
        RemoteCapability.navigation,
        (tv) => tv.press(NavigationKey.right),
      ),
    ),
  );
  static final ok = RemoteAction<GridRemoteViewModel>(
    'nav_ok',
    showLabel: false,
    holdable: true,
    builder: (context, remote) => (
      icon: Icons.check,
      label: 'OK',
      enabled: true,
      execute: () => remote.runTv(
        RemoteCapability.navigation,
        (tv) => tv.press(NavigationKey.enter),
      ),
    ),
  );
  static final home = RemoteAction<GridRemoteViewModel>(
    'nav_home',
    showLabel: false,
    holdable: true,
    builder: (context, remote) => (
      icon: Icons.home_outlined,
      label: 'Home',
      enabled: true,
      execute: () => remote.runTv(
        RemoteCapability.navigation,
        (tv) => tv.press(NavigationKey.home),
      ),
    ),
  );
  static final back = RemoteAction<GridRemoteViewModel>(
    'nav_back',
    showLabel: false,
    holdable: true,
    builder: (context, remote) => (
      icon: Icons.undo,
      label: 'Back',
      enabled: true,
      execute: () => remote.runTv(
        RemoteCapability.navigation,
        (tv) => tv.press(NavigationKey.back),
      ),
    ),
  );
  static final play = RemoteAction<GridRemoteViewModel>(
    'play',
    builder: (context, remote) => (
      icon: Icons.play_arrow,
      label: 'Play',
      enabled: true,
      execute: () => remote.sendMedia(MediaAction.play),
    ),
  );
  static final pause = RemoteAction<GridRemoteViewModel>(
    'pause',
    builder: (context, remote) => (
      icon: Icons.pause,
      label: 'Pause',
      enabled: true,
      execute: () => remote.sendMedia(MediaAction.pause),
    ),
  );

  /// One button that alternates Play and Pause, showing the next action.
  static final playbackToggle = RemoteAction<GridRemoteViewModel>(
    'playback_toggle',
    builder: (_, remote) => (
      icon: remote.mediaPlaying
          ? Icons.pause_circle_outline
          : Icons.play_circle_outline,
      label: remote.mediaPlaying ? 'Pause' : 'Play',
      enabled: true,
      execute: remote.togglePlayback,
    ),
  );

  static final playPause = RemoteAction<GridRemoteViewModel>(
    'play_pause',
    builder: (context, remote) {
      final playing = remote.mediaPlaying;
      return (
        icon: playing ? Icons.pause : Icons.play_arrow,
        label: playing ? 'Pause' : 'Play',
        enabled: true,
        execute: () =>
            remote.sendMedia(playing ? MediaAction.pause : MediaAction.play),
      );
    },
  );

  static final playStop = RemoteAction<GridRemoteViewModel>(
    'play_stop',
    builder: (context, remote) {
      final playing = remote.mediaPlaying;
      return (
        icon: playing ? Icons.stop : Icons.play_arrow,
        label: playing ? 'Stop' : 'Play',
        enabled: true,
        execute: () =>
            remote.sendMedia(playing ? MediaAction.stop : MediaAction.play),
      );
    },
  );

  static final stop = RemoteAction<GridRemoteViewModel>(
    'stop',
    builder: (context, remote) => (
      icon: Icons.stop,
      label: 'Stop',
      enabled: true,
      execute: () => remote.sendMedia(MediaAction.stop),
    ),
  );
  static final previous = RemoteAction<GridRemoteViewModel>(
    'previous',
    builder: (context, remote) => (
      icon: Icons.skip_previous,
      label: 'Previous',
      enabled: true,
      execute: () => remote.sendMedia(MediaAction.previous),
    ),
  );
  static final next = RemoteAction<GridRemoteViewModel>(
    'next',
    builder: (context, remote) => (
      icon: Icons.skip_next,
      label: 'Next',
      enabled: true,
      execute: () => remote.sendMedia(MediaAction.next),
    ),
  );
  static final rewind = RemoteAction<GridRemoteViewModel>(
    'rewind',
    builder: (context, remote) => (
      icon: Icons.fast_rewind,
      label: 'Rewind',
      enabled: true,
      execute: () => remote.sendMedia(MediaAction.rewind),
    ),
  );
  static final fastForward = RemoteAction<GridRemoteViewModel>(
    'fast_forward',
    builder: (context, remote) => (
      icon: Icons.fast_forward,
      label: 'Fast forward',
      enabled: true,
      execute: () => remote.sendMedia(MediaAction.fastForward),
    ),
  );
  static final menu = RemoteAction<GridRemoteViewModel>(
    'key_menu',
    builder: (context, remote) => (
      icon: Icons.keyboard_command_key,
      label: 'menu',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.menu),
    ),
  );
  static final info = RemoteAction<GridRemoteViewModel>(
    'key_info',
    builder: (context, remote) => (
      icon: Icons.keyboard_command_key,
      label: 'info',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.info),
    ),
  );
  static final guide = RemoteAction<GridRemoteViewModel>(
    'key_guide',
    builder: (context, remote) => (
      icon: Icons.keyboard_command_key,
      label: 'guide',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.guide),
    ),
  );
  static final exit = RemoteAction<GridRemoteViewModel>(
    'key_exit',
    builder: (context, remote) => (
      icon: Icons.keyboard_command_key,
      label: 'exit',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.exit),
    ),
  );
  static final red = RemoteAction<GridRemoteViewModel>(
    'key_red',
    builder: (context, remote) => (
      icon: Icons.keyboard_command_key,
      label: 'red',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.red),
    ),
  );
  static final green = RemoteAction<GridRemoteViewModel>(
    'key_green',
    builder: (context, remote) => (
      icon: Icons.keyboard_command_key,
      label: 'green',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.green),
    ),
  );
  static final yellow = RemoteAction<GridRemoteViewModel>(
    'key_yellow',
    builder: (context, remote) => (
      icon: Icons.keyboard_command_key,
      label: 'yellow',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.yellow),
    ),
  );
  static final blue = RemoteAction<GridRemoteViewModel>(
    'key_blue',
    builder: (context, remote) => (
      icon: Icons.keyboard_command_key,
      label: 'blue',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.blue),
    ),
  );
  static final keyDigit1 = RemoteAction<GridRemoteViewModel>(
    'key_digit1',
    builder: (context, remote) => (
      icon: null,
      label: '1',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.digit1),
    ),
  );
  static final keyDigit2 = RemoteAction<GridRemoteViewModel>(
    'key_digit2',
    builder: (context, remote) => (
      icon: null,
      label: '2',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.digit2),
    ),
  );
  static final keyDigit3 = RemoteAction<GridRemoteViewModel>(
    'key_digit3',
    builder: (context, remote) => (
      icon: null,
      label: '3',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.digit3),
    ),
  );
  static final keyDigit4 = RemoteAction<GridRemoteViewModel>(
    'key_digit4',
    builder: (context, remote) => (
      icon: null,
      label: '4',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.digit4),
    ),
  );
  static final keyDigit5 = RemoteAction<GridRemoteViewModel>(
    'key_digit5',
    builder: (context, remote) => (
      icon: null,
      label: '5',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.digit5),
    ),
  );
  static final keyDigit6 = RemoteAction<GridRemoteViewModel>(
    'key_digit6',
    builder: (context, remote) => (
      icon: null,
      label: '6',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.digit6),
    ),
  );
  static final keyDigit7 = RemoteAction<GridRemoteViewModel>(
    'key_digit7',
    builder: (context, remote) => (
      icon: null,
      label: '7',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.digit7),
    ),
  );
  static final keyDigit8 = RemoteAction<GridRemoteViewModel>(
    'key_digit8',
    builder: (context, remote) => (
      icon: null,
      label: '8',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.digit8),
    ),
  );
  static final keyDigit9 = RemoteAction<GridRemoteViewModel>(
    'key_digit9',
    builder: (context, remote) => (
      icon: null,
      label: '9',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.digit9),
    ),
  );
  static final keyDash = RemoteAction<GridRemoteViewModel>(
    'key_dash',
    builder: (context, remote) => (
      icon: null,
      label: '−',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.dash),
    ),
  );
  static final keyDigit0 = RemoteAction<GridRemoteViewModel>(
    'key_digit0',
    builder: (context, remote) => (
      icon: null,
      label: '0',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.digit0),
    ),
  );
  static final keyEnter = RemoteAction<GridRemoteViewModel>(
    'key_enter',
    builder: (context, remote) => (
      icon: null,
      label: 'Enter',
      enabled: true,
      execute: () => remote.sendKey(RemoteKey.enter),
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

  static final liveTv = _remoteKey(
    'live_tv_key',
    'Live TV',
    Icons.live_tv,
    RemoteKey.liveTv,
  );
  static final captions = _remoteKey(
    'captions_key',
    'Captions',
    Icons.closed_caption_outlined,
    RemoteKey.captions,
  );

  static final screenOff = RemoteAction<GridRemoteViewModel>(
    'screen_off',
    builder: (context, remote) => (
      icon: Icons.tv_off_outlined,
      label: 'Screen off',
      enabled: true,
      execute: () => remote.runTv(
        RemoteCapability.screenPower,
        (tv) => tv.turnOffScreen(),
      ),
    ),
  );
  static final screenOn = RemoteAction<GridRemoteViewModel>(
    'screen_on',
    builder: (context, remote) => (
      icon: Icons.tv_outlined,
      label: 'Screen on',
      enabled: true,
      execute: () =>
          remote.runTv(RemoteCapability.screenPower, (tv) => tv.turnOnScreen()),
    ),
  );

  static RemoteAction<GridRemoteViewModel> _remoteKey(
    String id,
    String label,
    IconData icon,
    RemoteKey key,
  ) => RemoteAction<GridRemoteViewModel>(
    id,
    builder: (context, remote) => (
      icon: icon,
      label: label,
      enabled: true,
      execute: () async {
        await remote.sendKey(key);
        if (key == RemoteKey.settings) {
          showCommandSent(context.buildContext);
        }
      },
    ),
  );

  static final muteToggle = RemoteAction<GridRemoteViewModel>(
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
            showCommandSent(context.buildContext);
          }
        },
      );
    },
  );
  static final muteOn = RemoteAction<GridRemoteViewModel>(
    'mute_on',
    builder: (context, remote) => (
      icon: Icons.volume_off_outlined,
      label: 'Mute',
      enabled: true,
      execute: () => remote.mute(true),
    ),
  );
  static final muteOff = RemoteAction<GridRemoteViewModel>(
    'mute_off',
    builder: (context, remote) => (
      icon: Icons.volume_up_outlined,
      label: 'Unmute',
      enabled: true,
      execute: () => remote.mute(false),
    ),
  );
  static final voice = RemoteAction<GridRemoteViewModel>(
    'voice',
    builder: (context, remote) => (
      icon: Icons.mic_none,
      label: 'Voice',
      enabled: true,
      execute: () =>
          remote.runTv(RemoteCapability.voice, (tv) => tv.startVoiceControl()),
    ),
  );
  static final gameMode = RemoteAction<GridRemoteViewModel>(
    'game_mode',
    builder: (context, remote) => (
      icon: Icons.sports_esports_outlined,
      label: 'Game mode',
      enabled: true,
      execute: () =>
          remote.runTv(RemoteCapability.gameMode, (tv) => tv.toggleGameMode()),
    ),
  );
  static final watch = RemoteAction<GridRemoteViewModel>(
    'watch_companion',
    builder: (context, remote) => (
      icon: Icons.watch_outlined,
      label: 'Watch companion',
      enabled: true,
      execute: () =>
          remote.runTv(RemoteCapability.watch, (tv) => tv.syncWatchCompanion()),
    ),
  );
  static final pointerClick = RemoteAction<GridRemoteViewModel>(
    'pointer_click',
    builder: (context, remote) => (
      icon: Icons.mouse_outlined,
      label: 'Click',
      enabled: true,
      execute: () => remote.runTv(RemoteCapability.pointer, (tv) => tv.click()),
    ),
  );
  static final volumeUp = RemoteAction<GridRemoteViewModel>(
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
  static final volumeDown = RemoteAction<GridRemoteViewModel>(
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
  static final volumePreset = RemoteAction<GridRemoteViewModel>(
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
  static final channelUp = RemoteAction<GridRemoteViewModel>(
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
  static final channelDown = RemoteAction<GridRemoteViewModel>(
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
      RemoteInput<GridRemoteViewModel, ({double x, double y, bool scroll})>(
        'touchpad',
        icon: (_) => Icons.touch_app_outlined,
        commit: (remote, motion) =>
            remote.move(motion.x, motion.y, scroll: motion.scroll),
      );
  static final keyboard =
      RemoteInput<GridRemoteViewModel, ({String text, bool submit})>(
        'keyboard',
        icon: (_) => Icons.keyboard_outlined,
        slots: 4,
        commit: (remote, entry) =>
            remote.sendText(entry.text, submit: entry.submit),
      );
  static final activity = RemoteInfo<GridRemoteViewModel>(
    'current_activity',
    defaultLabel: 'Activity',
    showLabelByDefault: false,
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
  static final app = RemoteInfo<GridRemoteViewModel>(
    'current_app',
    defaultLabel: 'App',
    hiddenWhenOffline: true,
    icon: (_) => Icons.live_tv,
    read: (context) {
      final reading = activity.read(context);
      return RemoteReading(reading.title, leading: reading.leading);
    },
  );
  static RemoteReading _inputReading(DeviceInput? input) =>
      RemoteReading(input?.name ?? 'Current input unavailable');

  static final channelNumber = RemoteInfo<GridRemoteViewModel>(
    'channel_number',
    defaultLabel: 'CH',
    supportsOfflineIndicator: true,
    icon: (_) => Icons.live_tv,
    read: (context) =>
        RemoteReading(context.remote.content?.channelNumber ?? '—'),
  );
  static final channelName = RemoteInfo<GridRemoteViewModel>(
    'channel_name',
    defaultLabel: 'Channel',
    icon: (_) => Icons.live_tv,
    read: (context) => RemoteReading(
      context.remote.content?.channelName ?? 'Channel unavailable',
    ),
  );
  static final currentInput = RemoteInfo<GridRemoteViewModel>(
    'current_input',
    defaultLabel: 'Input',
    slots: 2,
    icon: (_) => Icons.input,
    watch: (context) => context.remote.connection
        .tvWith(RemoteCapability.currentInput)
        ?.currentInputChanges
        .map(_inputReading),
    read: (context) => _inputReading(context.remote.currentInput),
  );
  static final inputs = RemoteCollection<GridRemoteViewModel, DeviceInput>(
    'pinned_inputs',
    title: 'Inputs',
    icon: (_) => Icons.input,
    load: (remote) => remote.inputs(),
    entryId: (input) => input.id,
    entryName: (input) => input.name,
    fromOption: DeviceInput.new,
    sample: (data) => data.inputs,
    onSelected: (remote, input) => remote.selectInput(input.id),
    onEmpty: (remote) =>
        remote.runTv(RemoteCapability.inputs, (tv) => tv.openInputPicker()),
  );
  static final channels = RemoteCollection<GridRemoteViewModel, DeviceChannel>(
    'pinned_channels',
    title: 'Channels',
    icon: (_) => Icons.live_tv,
    load: (remote) => remote.channels(),
    entryId: (channel) => channel.id,
    entryName: (channel) => '${channel.number} ${channel.name}'.trim(),
    fromOption: (id, name) => DeviceChannel(id, name, ''),
    sample: (data) => data.channels,
    onSelected: (remote, channel) => remote.selectChannel(channel.id),
  );
  static final channelCatalog =
      RemoteCollection<GridRemoteViewModel, DeviceChannel>(
        'channel_catalog',
        title: 'Reported channels',
        icon: (_) => Icons.live_tv,
        load: (remote) => remote.channels(),
        entryId: (channel) => channel.id,
        entryName: (channel) => '${channel.number} ${channel.name}'.trim(),
        fromOption: (id, name) => DeviceChannel(id, name, ''),
        sample: (data) => data.channels,
        onSelected: (_, _) async {},
        readOnly: true,
      );
  static final volume = RemoteInfo<GridRemoteViewModel>(
    'current_volume',
    defaultLabel: 'VOL',
    supportsOfflineIndicator: true,
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
  static final volumeSlider = RemoteInput<GridRemoteViewModel, double>(
    'volume_slider',
    icon: (_) => Icons.tune,
    slots: 2,
    current: (context) => context.remote.volume?.volume.toDouble(),
    preview: (remote, value) => remote.previewVolume(value),
    commit: (remote, value) => remote.setVolume(value),
  );
  static final accessories =
      RemoteCollection<GridRemoteViewModel, BluetoothAccessory>(
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
        onSelected: (remote, accessory) => remote.runTv(
          RemoteCapability.bluetoothAccessories,
          (tv) => tv.toggleBluetoothAccessory(accessory.id),
        ),
      );

  static final applications =
      RemoteCollection<GridRemoteViewModel, DeviceApplication>(
        'pinned_apps',
        title: 'Apps',
        icon: (_) => Icons.apps,
        trackedByDevice: true,
        artwork: (app) => app.artwork,
        leading: (id, name) => TvAppIcon(appId: id, name: name),
        load: (remote) => remote.applications(),
        entryId: (app) => app.id,
        entryName: (app) => app.name,
        fromOption: DeviceApplication.new,
        sample: (data) => data.applications,
        onSelected: (remote, app) => remote.launchDashboardApp(app),
      );
}
