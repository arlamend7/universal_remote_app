import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../../widgets/grid/models/remote_preview_data.dart';
import '../../items/standard_items.dart';
import '../../widgets/dialogs/confirmation_dialog.dart';
import '../modals/text_entry_sheet.dart';
import '../../widgets/dialogs/device_choice_sheet.dart';

final class GridRemoteViewModel implements TvRemoteDevice {
  GridRemoteViewModel(this.remote, {this.previewData});
  final RemotePreviewData? previewData;
  final RemotePanel remote;
  RemoteElementContext elementContext(
    GridWidgetKind kind, {
    Axis position = Axis.horizontal,
  }) => RemoteElementContext(kind: kind, remote: remote, position: position);

  /// The icon a registered element chooses for this remote's current state.
  IconData iconOf(
    RemoteElement<Object> element,
    GridWidgetKind kind, {
    Axis position = Axis.horizontal,
  }) => element.icon!(elementContext(kind, position: position));

  bool get ready => remote.ready;
  bool supports(RemoteCapability capability) =>
      remote.connection.supports(capability);

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
  Future<void> navigate(NavigationKey key) => remote.press(key);
  @override
  Future<void> channelUp() => remote.channelUp();
  @override
  Future<void> channelDown() => remote.channelDown();
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
  int? get volumeLevel => remote.offline ? null : remote.volume?.volume;
  @override
  Future<void> volumeUp() => remote.volumeUp();
  @override
  Future<void> volumeDown() => remote.volumeDown();
  @override
  void previewVolume(double value) => remote.previewVolume(value);
  @override
  Future<void> setVolume(double value) => remote.setVolume(value);
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
  Future<void> launchApp(DeviceApplication app) => launch(app.id, app.name);

  Future<void> launch(String id, String name) => execute(() async {
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
  List<(String, String)> targets(GridItem item) {
    if (item.kind.name == 'recentApps' && previewData != null) {
      return previewData!.applications;
    }
    final configured = widgetTargets(item.config['targets']);
    if (configured.isNotEmpty || previewData == null) {
      return configured;
    }
    if (item.kind.name.startsWith('input')) {
      return previewData!.inputs;
    }
    if (item.kind.name.startsWith('channel')) {
      return previewData!.channels;
    }
    return previewData!.applications;
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
  @override
  Future<void> media(MediaAction action) => execute(() async {
    await tv(RemoteCapability.media)?.sendMedia(action);
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
    if (value == null) {
      return remote.toggleMute();
    }
    return remote.connection.execute(() async {
      await tv(RemoteCapability.volume)?.setMuted(value);
    }, refreshVolume: true);
  }

  Future<void> details(BuildContext context) =>
      remote.showDeviceDetails(context);
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
        (collection.entryId(entry), collection.entryName(entry)),
    ]);
    if (id == null || !identical(owner, remote.connection.controller)) {
      return;
    }
    final chosen = choices.firstWhere(
      (entry) => collection.entryId(entry) == id,
    );
    await collection.onSelected(this, chosen);
  }

  Future<void> keyboard(
    BuildContext context,
    KeyboardConfiguration configuration,
  ) async {
    final owner = remote.connection.controller;
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (_) => const TextEntrySheet(),
    );
    if (text == null || !identical(remote.connection.controller, owner)) {
      return;
    }
    await RemoteItemRegistry.resolve(GridWidgetKind.keyboard)
        .element(TvItems.keyboard)
        .commit(this, (text: text, submit: configuration.submitAfterTyping));
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

  Future<void> power(BuildContext context, GridItem item) async {
    final action = item.element(powerOffAction);
    if (item.config['confirm'] == 'false') {
      await action.onPressed(remote, null);
      return;
    }
    await remote.powerOff(
      context,
      onConfirmed: () => action.onPressed(remote, null),
    );
  }

  Future<void> sleep(
    BuildContext context,
    GridItem item,
    DateTime? deadline,
  ) async {
    final action = item.element(sleepTimerAction);
    if (deadline != null) {
      await action.onPressed(remote, null);
      return;
    }
    final device = remote.device;
    final owner = remote.connection.controller;
    if (device == null) {
      return;
    }
    final minutes =
        int.tryParse(item.config['minutes'] ?? '')?.clamp(1, 180) ?? 30;
    final confirmed = await ConfirmationDialog.ask(
      context,
      title: 'Turn off in $minutes minutes?',
      confirmLabel: 'Start timer',
      message: 'Keep this app running and connected to this device. Background suspension can delay the local timer.',
    );
    if (!confirmed ||
        remote.device?.id != device.id ||
        !identical(remote.connection.controller, owner)) {
      return;
    }
    await action.onPressed(remote, Duration(minutes: minutes));
  }
}
