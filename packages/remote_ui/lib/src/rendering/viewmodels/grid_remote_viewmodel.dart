import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../../widgets/grid/models/remote_preview_data.dart';
import '../../widgets/dialogs/device_choice_sheet.dart';

final class GridRemoteViewModel implements TvRemoteDevice {
  GridRemoteViewModel(this.remote, {this.previewData});
  final RemotePreviewData? previewData;
  final RemotePanel remote;
  RemoteElementContext elementContext(
    GridItem item, {
    BuildContext? buildContext,
  }) => RemoteElementContext(
    remote: remote,
    settings: item.config,
    buildContext: buildContext,
  );

  /// Resolves [action] for [item] and runs it; does nothing when this panel
  /// has no device for it.
  Future<void>? press(
    RemoteAction<Object> action,
    GridItem item,
    BuildContext context,
  ) => resolve(action, elementContext(item, buildContext: context))?.execute();

  /// Resolves [action] for the device type it was registered for, or null
  /// when this panel has no such device (an air conditioner action while a TV
  /// is connected).
  ResolvedAction? resolve(
    RemoteAction<Object> action,
    RemoteElementContext context,
  ) {
    if (action is RemoteAction<TvRemoteDevice>) {
      return action.builder(context, this);
    }
    if (action is RemoteAction<RemotePanel>) {
      return action.builder(context, remote);
    }
    final device = remote.connection.controller;
    if (action is RemoteAction<ACRemoteBase> && device is ACRemoteBase) {
      final resolved = action.builder(context, device);
      return (
        icon: resolved.icon,
        label: resolved.label,
        enabled: resolved.enabled,
        execute: () => execute(resolved.execute),
      );
    }
    return null;
  }

  bool get ready => remote.ready;

  /// The connected TV driver, only when it reports [capability].
  TVRemoteBase? tv(RemoteCapability capability) =>
      remote.connection.tvWith(capability);
  Future<void> execute(Future<void> Function() action) =>
      remote.connection.execute(action);
  @override
  DeviceInput? get currentInput =>
      tv(RemoteCapability.currentInput)?.currentInput;
  @override
  CurrentContent? get currentActivity => remote.content;
  @override
  Future<void> navigate(NavigationKey key) => execute(() async {
    await tv(RemoteCapability.navigation)?.press(key);
  });
  @override
  Future<void> channelUp() => _changeChannel((tv) => tv.channelUp());
  @override
  Future<void> channelDown() => _changeChannel((tv) => tv.channelDown());

  Future<void> _changeChannel(Future<void> Function(TVRemoteBase tv) change) =>
      execute(() async {
        final channels = tv(RemoteCapability.channels);
        if (channels != null) {
          await change(channels);
        }
        unawaited(remote.connection.refreshContent());
      });
  @override
  Future<void> sendText(String text, {bool submit = false}) =>
      execute(() async {
        final keyboard = tv(RemoteCapability.textInput);
        if (keyboard == null) {
          return;
        }
        final owner = remote.connection.controller;
        await keyboard.sendText(text);
        if (submit && identical(owner, remote.connection.controller)) {
          await keyboard.sendEnter();
        }
      });

  @override
  Future<List<DeviceInput>> installedInputs() {
    final inputs = tv(RemoteCapability.inputs);
    if (inputs == null) {
      throw const RemoteException('inputs', 'This TV does not expose inputs.');
    }
    return inputs.inputs();
  }

  @override
  Future<List<DeviceChannel>> installedChannels() {
    final channels = tv(RemoteCapability.channelSelection);
    if (channels == null) {
      throw const RemoteException(
        'channels',
        'This TV does not expose a channel list.',
      );
    }
    return channels.channels();
  }

  @override
  Future<void> volumeUp() => _changeVolume((tv) => tv.volumeUp());
  @override
  Future<void> volumeDown() => _changeVolume((tv) => tv.volumeDown());
  @override
  void previewVolume(double value) => remote.previewVolume(value);
  @override
  Future<void> setVolume(double value) =>
      _changeVolume((tv) => tv.setVolume(value.round()));

  Future<void> _changeVolume(Future<void> Function(TVRemoteBase tv) change) =>
      remote.connection.execute(() async {
        final volume = tv(RemoteCapability.volume);
        if (volume != null) {
          await change(volume);
        }
      }, refreshVolume: true);
  @override
  Future<List<DeviceApplication>> installedApps() async {
    final apps = tv(RemoteCapability.applications);
    if (apps == null) {
      throw const RemoteException(
        'apps',
        'This TV does not expose an app library.',
      );
    }
    final owner = remote.connection.controller;
    final reported = await apps.applications();
    if (identical(owner, remote.connection.controller)) {
      remote.connection.refreshControls();
    }
    return reported;
  }

  bool isAppMissing(String id) {
    if (previewData != null) {
      return false;
    }
    return tv(RemoteCapability.applications)?.reportedApplicationIds
            ?.contains(id) ==
        false;
  }

  @override
  Future<void> launchApp(DeviceApplication app) => execute(() async {
    final (id, name) = (app.id, app.name);
    final apps = tv(RemoteCapability.applications);
    if (apps == null) {
      throw const RemoteException('apps', 'App launching is unavailable.');
    }
    final device = remote.device!;
    final owner = remote.connection.controller;
    await apps.launchApplication(id);
    if (!identical(remote.connection.controller, owner)) {
      return;
    }
    final latest =
        remote.profiles.value
            .where((item) => item.id == device.id)
            .firstOrNull ??
        device;
    final recent = widgetTargets(latest.metadata['recentAppLaunches']);
    await remote.saveProfile(
      copyDevice(
        latest,
        metadata: {
          ...latest.metadata,
          'recentAppLaunches': encodeWidgetTargets(
            [
              (id, name),
              ...recent.where((item) => item.$1 != id),
            ].take(12).toList(),
          ),
        },
      ),
    );
    unawaited(remote.connection.refreshContent());
  });

  /// Pinned entries of a collection item; previews fall back to the
  /// collection's sample entries.
  List<(String, String)> targets(
    GridItem item,
    RemoteCollection<TvRemoteDevice, Object> collection,
  ) {
    final configured = widgetTargets(item.config['targets']);
    final preview = previewData;
    if (configured.isNotEmpty || preview == null) {
      return configured;
    }
    return collection.sample(preview);
  }

  List<(String, String)> get recentApps {
    final device = remote.profiles.value
        .where((item) => item.id == remote.device?.id)
        .firstOrNull;
    return widgetTargets(device?.metadata['recentAppLaunches']);
  }

  @override
  Future<void> input(String id) => execute(() async {
    await tv(RemoteCapability.inputs)?.selectInput(id);
    unawaited(remote.connection.refreshContent());
  });
  @override
  Future<void> channel(String id) => execute(() async {
    await tv(RemoteCapability.channelSelection)?.selectChannel(id);
    unawaited(remote.connection.refreshContent());
  });
  static final _playback = Expando<ValueNotifier<bool>>();

  ValueNotifier<bool>? get playbackChanges {
    final session = remote.connection.controller;
    if (session == null || previewData != null) {
      return null;
    }
    return _playback[session] ??= ValueNotifier(false);
  }

  @override
  bool get mediaPlaying => playbackChanges?.value ?? false;

  @override
  Future<void> togglePlayback() =>
      media(mediaPlaying ? MediaAction.pause : MediaAction.play);

  @override
  Future<void> media(MediaAction action) => execute(() async {
    final controller = tv(RemoteCapability.media);
    if (controller == null) {
      return;
    }
    final playback = playbackChanges;
    await controller.sendMedia(action);
    if (action == MediaAction.play) {
      playback?.value = true;
    }
    if (action == MediaAction.pause || action == MediaAction.stop) {
      playback?.value = false;
    }
  });
  @override
  Future<void> key(RemoteKey key) => execute(() async {
    await tv(RemoteCapability.pointer)?.sendKey(key);
  });
  @override
  Future<void> move(double x, double y, {bool scroll = false}) async {
    final pointer = tv(RemoteCapability.pointer);
    if (pointer == null || !ready) {
      return;
    }
    try {
      if (scroll) {
        await pointer.scroll(x, y);
        return;
      }
      await pointer.movePointer(x, y);
    } catch (_) {
      remote.connection.reportError(
        'The TV pointer connection is unavailable.',
      );
    }
  }

  @override
  Future<void> click() => execute(() async {
    await tv(RemoteCapability.pointer)?.click();
  });
  @override
  Future<void> mute(bool? value) {
    final muted = remote.volume?.muted;
    final target = value ?? (muted == null ? null : !muted);
    if (target == null) {
      return Future.value();
    }
    return _changeVolume((tv) => tv.setMuted(target));
  }

  @override
  Future<List<BluetoothAccessory>> bluetoothAccessories() async {
    final driver = tv(RemoteCapability.bluetoothAccessories);
    if (driver == null) {
      return [];
    }
    return driver.bluetoothAccessories();
  }

  @override
  Future<void> toggleBluetoothAccessory(String id) => execute(() async {
    await tv(RemoteCapability.bluetoothAccessories)
        ?.toggleBluetoothAccessory(id);
  });

  Future<void> choose<T>(
    BuildContext context,
    String title,
    RemoteCollection<TvRemoteDevice, T> collection,
  ) async {
    final owner = remote.connection.controller;
    List<T>? entries;
    await execute(() async {
      entries = await collection.load(this);
    });
    final choices = entries;
    if (choices == null ||
        !context.mounted ||
        !identical(owner, remote.connection.controller)) {
      return;
    }
    final id = await DeviceChoiceSheet.choose(context, title, [
      for (final entry in choices)
        (
          collection.entryId(entry),
          (collection.choiceName ?? collection.entryName)(entry),
        ),
    ], grid: collection.leading != null);
    if (id == null || !identical(owner, remote.connection.controller)) {
      return;
    }
    final chosen = choices.firstWhere(
      (entry) => collection.entryId(entry) == id,
    );
    await collection.onSelected(this, chosen);
  }

  @override
  Future<void> startVoiceControl() => execute(() async {
    await tv(RemoteCapability.voice)?.startVoiceControl();
  });

  @override
  Future<void> toggleGameMode() => execute(() async {
    await tv(RemoteCapability.gameMode)?.toggleGameMode();
  });

  @override
  Future<void> syncWatchCompanion() => execute(() async {
    await tv(RemoteCapability.watch)?.syncWatchCompanion();
  });
}
