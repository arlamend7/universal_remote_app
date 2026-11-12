import 'package:flutter/foundation.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../domains/connection/services/connection_controller.dart';
import '../modals/show_remote_status.dart';

import 'package:remote_ui/remote_ui.dart';

import '../../devices/modals/edit_device.dart';
import '../modals/confirm_tv_certificate.dart';
import '../../devices/modals/show_device_details.dart' as details_dialog;
import '../../../../routes/open_remote_editor.dart';

/// Presentation actions consume capabilities, never LG command strings.
class RemoteViewModel implements RemotePanel {
  RemoteViewModel(this.dependencies);
  final AppDependencies dependencies;
  ConnectionController get connection => dependencies.connection;
  late final shellChanges = Listenable.merge([
    connection.selected,
    dependencies.grids.revision,
    dependencies.savedDevices.devices,
  ]);
  late final sessionChanges = Listenable.merge([
    connection.state,
    connection.error,
    connection.errorCode,
    connection.commandBusy,
    connection.disconnectReason,
  ]);
  late final controlsChanges = Listenable.merge([
    connection.state,
    connection.commandBusy,
    connection.revision,
  ]);
  late final volumeChanges = Listenable.merge([
    controlsChanges,
    connection.volume,
  ]);
  late final contentChanges = Listenable.merge([
    controlsChanges,
    connection.currentContent,
  ]);
  late final changes = Listenable.merge([
    shellChanges,
    sessionChanges,
    volumeChanges,
    contentChanges,
  ]);
  @override
  ValueListenable<List<RemoteDevice>> get profiles =>
      dependencies.savedDevices.devices;
  @override
  ValueListenable<DateTime?> get sleepDeadline => dependencies.sleep.deadline;
  @override
  Future<void> saveProfile(RemoteDevice device) =>
      dependencies.savedDevices.save(device);
  @override
  void scheduleSleep(RemoteDevice device, Duration duration) =>
      dependencies.sleep.schedule(device, duration);
  @override
  void cancelSleep() => dependencies.sleep.cancel();
  @override
  Future<void> showDeviceDetails(BuildContext context) async {
    final target = device;
    if (target != null) {
      await details_dialog.showDeviceDetails(context, dependencies, target);
    }
  }

  Future<void> showStatus(BuildContext context) =>
      showRemoteStatus(context, this);
  RemoteDevice? get device => connection.selected.value;
  DeviceConnectionState get state => connection.state.value;
  String? get error => connection.error.value;
  GridLayout? get grid =>
      device == null ? null : dependencies.grids.layoutFor(device!);
  String get displayName =>
      dependencies.savedDevices.byId(device?.id)?.name ??
      device?.name ??
      'Remote';
  CurrentContent? get content =>
      offline ? null : connection.currentContent.value;
  String get contentTitle =>
      content?.appName ?? content?.appId ?? 'Current activity unavailable';
  String get contentSubtitle {
    final current = content;
    if (current == null) {
      return 'Not reported by this TV';
    }
    if (!current.isLiveTv) {
      return current.position == null
          ? 'Open on TV'
          : _playbackTime(current.position!, current.duration);
    }
    final channel = [
      current.channelNumber,
      current.channelName,
      current.programTitle,
    ].whereType<String>().join(' · ');
    return channel.isEmpty ? 'Channel not reported' : channel;
  }

  String _playbackTime(Duration position, Duration? duration) {
    String format(Duration value) =>
        '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
    return duration == null
        ? format(position)
        : '${format(position)} / ${format(duration)}';
  }

  @override
  DeviceInput? get currentInput =>
      connection.tvWith(RemoteCapability.currentInput)?.currentInput;
  Future<void> customize(BuildContext context) async {
    final current = device;
    if (current == null) {
      return;
    }
    await openRemoteEditor(context, dependencies, current);
  }

  Future<void> switchDevice(BuildContext context) async {
    final choices = dependencies.savedDevices.devices.value;
    final id = await DeviceChoiceSheet.choose(context, 'Choose a TV', [
      ...choices.map((item) => (item.id, item.name)),
      ('@add-tv', 'Add TV'),
    ]);
    if (id == null || !context.mounted) {
      return;
    }
    if (id == '@add-tv') {
      final added = await editDevice(context, dependencies);
      if (added != null) {
        await connection.connect(added);
      }
      return;
    }
    final target = choices.where((item) => item.id == id).firstOrNull;
    if (target != null) {
      await connection.connect(target);
    }
  }

  VolumeState? get volume => connection.volume.value;
  bool get ready =>
      state == DeviceConnectionState.connected && !connection.commandBusy.value;
  bool get isPairing =>
      state == DeviceConnectionState.pairing ||
      state == DeviceConnectionState.connecting ||
      state == DeviceConnectionState.reconnecting;
  bool get offline => state == DeviceConnectionState.disconnected;
  bool get busy => connection.commandBusy.value;
  bool get canReviewCertificate {
    final current = device;
    return offline &&
        current != null &&
        dependencies.providers.canReviewCertificate(
          current,
          connection.errorCode.value,
        );
  }

  bool get canPowerOff => ready && supports(RemoteCapability.power);
  RemoteDevice? get _wakeTarget =>
      dependencies.savedDevices.byId(device?.id) ?? device;
  bool get canWake {
    final target = _wakeTarget;
    return target != null && dependencies.providers.canWake(target);
  }

  @override
  bool supports(RemoteCapability capability) => connection.supports(capability);
  String get status => switch (state) {
    DeviceConnectionState.connected => 'Connected',
    DeviceConnectionState.connecting => 'Connecting',
    DeviceConnectionState.pairing => 'Waiting for TV approval',
    DeviceConnectionState.reconnecting => 'Reconnecting',
    DeviceConnectionState.disconnected => offlineStatus,
  };
  String get offlineStatus {
    if (connection.disconnectReason.value == DisconnectReason.poweredOff) {
      return 'Power off requested';
    }
    if (connection.errorCode.value == 'network' ||
        connection.errorCode.value == 'timeout') {
      return 'Unreachable';
    }
    if (error != null) {
      return 'Connection error';
    }
    if (connection.disconnectReason.value == DisconnectReason.connectionLost) {
      return 'Connection lost';
    }
    return 'Disconnected';
  }

  String get statusExplanation {
    if (error != null) {
      return error!;
    }
    if (connection.disconnectReason.value == DisconnectReason.poweredOff) {
      return canWake
          ? 'The power-off command was accepted. You can send a wake request from the power button.'
          : 'The power-off command was accepted. Turn on the TV with its physical remote, then connect again.';
    }
    return canWake
        ? 'Send a wake request if the TV is off, or connect if it is already on. Network wake must be enabled on the TV.'
        : 'This integration has no configured remote wake. Turn on the TV with its physical remote, check its network, then connect again. A disconnected socket does not confirm that the TV is powered off.';
  }

  void previewVolume(double value) {
    connection.volume.value = VolumeState(value.round(), volume?.muted);
  }

  Future<void> disconnect() => connection.disconnect();
  Future<void> retry() async {
    final current = device;
    if (current == null) {
      return;
    }
    await connection.connect(current);
  }

  Future<void> wake() async {
    final current = _wakeTarget;
    if (current == null) {
      return;
    }
    await connection.turnOn(current);
  }

  Future<void> edit(BuildContext context) async {
    final edited = await editDevice(context, dependencies, device: device);
    if (edited == null) {
      return;
    }
    await connection.connect(edited);
  }

  Future<void> reviewCertificate(BuildContext context) =>
      connection.execute(() => _reviewCertificate(context));

  Future<void> _reviewCertificate(BuildContext context) async {
    final current = device;
    if (current == null || !canReviewCertificate) {
      return;
    }
    final certificate = await dependencies.inspectCertificate(
      current.endpoints.first,
    );
    if (!context.mounted || !identical(device, current) || !offline) {
      return;
    }
    final previous = dependencies.providers
        .networkConfiguration(current)
        .certificate;
    final confirmed = await confirmTvCertificate(
      context,
      current,
      certificate,
      replacing: previous.isNotEmpty && previous != certificate.derBase64,
    );
    if (!confirmed || !identical(device, current) || !offline) {
      return;
    }
    final trusted = dependencies.providers.trustCertificate(
      current,
      certificate.derBase64,
    );
    await dependencies.savedDevices.updateExisting(trusted.id, (_) => trusted);
    if (!identical(device, current) || !offline) {
      return;
    }
    await connection.connect(trusted);
  }

  Future<void> powerOff(
    BuildContext context, {
    Future<void> Function()? onConfirmed,
  }) async {
    final owner = connection.controller;
    if (!supports(RemoteCapability.power)) {
      return;
    }
    final confirmed = await ConfirmationDialog.ask(
      context,
      title: 'Turn off $displayName?',
      confirmLabel: 'Power off',
    );
    if (!confirmed || !identical(connection.controller, owner)) {
      return;
    }
    await (onConfirmed ?? connection.powerOff)();
  }
}
