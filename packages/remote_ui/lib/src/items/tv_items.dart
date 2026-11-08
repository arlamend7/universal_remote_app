import 'package:flutter/material.dart' show Icon, Icons;
import 'package:remote_core/remote_core.dart';

import '../layout/models/enums/grid_widget_kind.dart';
import '../devices/tv_remote_device.dart';
import '../elements/remote_action.dart';
import '../elements/remote_collection.dart';
import '../elements/remote_info.dart';
import '../elements/remote_reading.dart';
import '../elements/remote_input.dart';
import '../widgets/apps/tv_app_icon.dart';

abstract final class TvItems {
  static final voice = RemoteAction<TvRemoteDevice, Null>(
    'voice',
    icon: (_) => Icons.mic_none,
    onPressed: (remote, _) => remote.startVoiceControl(),
  );

  static final gameMode = RemoteAction<TvRemoteDevice, Null>(
    'game_mode',
    icon: (_) => Icons.sports_esports_outlined,
    onPressed: (remote, _) => remote.toggleGameMode(),
  );

  static final watch = RemoteAction<TvRemoteDevice, Null>(
    'watch_companion',
    icon: (_) => Icons.watch_outlined,
    onPressed: (remote, _) => remote.syncWatchCompanion(),
  );

  static final navigation = RemoteAction<TvRemoteDevice, NavigationKey>(
    'navigation',
    icon: (_) => Icons.gamepad_outlined,
    onPressed: (remote, key) => remote.navigate(key),
  );
  static final channelUp = RemoteAction<TvRemoteDevice, Null>(
    'channel_up',
    icon: (_) => Icons.add,
    onPressed: (remote, _) => remote.channelUp(),
  );
  static final channelDown = RemoteAction<TvRemoteDevice, Null>(
    'channel_down',
    icon: (_) => Icons.remove,
    onPressed: (remote, _) => remote.channelDown(),
  );
  static final media = RemoteAction<TvRemoteDevice, MediaAction>(
    'media',
    icon: (_) => Icons.play_arrow,
    onPressed: (remote, action) => remote.media(action),
  );
  static final specialKey = RemoteAction<TvRemoteDevice, RemoteKey>(
    'special_key',
    icon: (_) => Icons.keyboard_outlined,
    onPressed: (remote, key) => remote.key(key),
  );
  static final pointerClick = RemoteAction<TvRemoteDevice, Null>(
    'pointer_click',
    icon: (_) => Icons.mouse_outlined,
    onPressed: (remote, _) => remote.click(),
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
  static final currentInput = RemoteInfo<TvRemoteDevice>(
    'current_input',
    slots: 2,
    icon: (_) => Icons.input,
    read: (context) => RemoteReading(
      context.remote.currentInput?.name ?? 'Current input unavailable',
    ),
  );
  static final inputs = RemoteCollection<TvRemoteDevice, DeviceInput>(
    'pinned_inputs',
    icon: (_) => Icons.input,
    load: (remote) => remote.installedInputs(),
    entryId: (input) => input.id,
    entryName: (input) => input.name,
    onSelected: (remote, input) => remote.input(input.id),
  );
  static final channels = RemoteCollection<TvRemoteDevice, DeviceChannel>(
    'pinned_channels',
    icon: (_) => Icons.live_tv,
    load: (remote) => remote.installedChannels(),
    entryId: (channel) => channel.id,
    entryName: (channel) => '${channel.number} ${channel.name}'.trim(),
    onSelected: (remote, channel) => remote.channel(channel.id),
  );
  static final mute = RemoteAction<TvRemoteDevice, bool?>(
    'mute',
    icon: (context) => switch (context.kind) {
      GridWidgetKind.muteOn => Icons.volume_off_outlined,
      GridWidgetKind.muteOff => Icons.volume_up_outlined,
      _ =>
        context.remote.volume?.muted == true
            ? Icons.volume_up_outlined
            : Icons.volume_off_outlined,
    },
    onPressed: (remote, value) => remote.mute(value),
  );
  static final volumeUp = RemoteAction<TvRemoteDevice, Null>(
    'volume_up',
    icon: (_) => Icons.add,
    onPressed: (remote, _) => remote.volumeUp(),
  );
  static final volumeDown = RemoteAction<TvRemoteDevice, Null>(
    'volume_down',
    icon: (_) => Icons.remove,
    onPressed: (remote, _) => remote.volumeDown(),
  );
  static final volume = RemoteInfo<TvRemoteDevice>(
    'current_volume',
    icon: (_) => Icons.volume_up_outlined,
    read: (context) {
      final level = context.remote.volume?.volume;
      return RemoteReading(level == null ? '—' : '$level');
    },
  );
  static final volumeSlider = RemoteInput<TvRemoteDevice, double>(
    'volume_slider',
    icon: (_) => Icons.tune,
    slots: 2,
    preview: (remote, value) => remote.previewVolume(value),
    commit: (remote, value) => remote.setVolume(value),
  );
  static final applications =
      RemoteCollection<TvRemoteDevice, DeviceApplication>(
        'pinned_apps',
        icon: (_) => Icons.apps,
        load: (remote) => remote.installedApps(),
        entryId: (app) => app.id,
        entryName: (app) => app.name,
        onSelected: (remote, app) => remote.launchApp(app),
      );
}
