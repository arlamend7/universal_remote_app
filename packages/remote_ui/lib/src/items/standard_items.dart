import 'package:flutter/material.dart' show Icons;
import 'package:remote_core/remote_core.dart';

import '../elements/remote_action.dart';
import '../elements/remote_info.dart';
import '../elements/remote_reading.dart';
import '../host/remote_panel.dart';
import '../widgets/dialogs/confirmation_dialog.dart';
import '../definitions/enums/remote_item_category.dart';
import '../definitions/layouts/layouts.dart';
import '../configuration/remote_setting.dart';
import '../definitions/remote_item_definition.dart';

final powerOffAction = RemoteAction<RemotePanel>(
  'power_off',
  builder: (context, remote) => (
    icon: Icons.power_settings_new,
    label: 'Power off',
    enabled: true,
    execute: () async {
      if (context.settings['confirm'] == 'false') {
        await remote.connection.powerOff();
        return;
      }
      await remote.powerOff(
        context.buildContext!,
        onConfirmed: remote.connection.powerOff,
      );
    },
  ),
);

final sleepTimerAction = RemoteAction<RemotePanel>(
  'sleep_timer',
  slots: 2,
  builder: (context, remote) => (
    icon: Icons.bedtime_outlined,
    label: remote.sleepDeadline.value == null
        ? 'Sleep ${context.settings['minutes'] ?? '30'} min'
        : 'Cancel sleep timer',
    enabled: true,
    execute: () async {
      if (remote.sleepDeadline.value != null) {
        remote.cancelSleep();
        return;
      }
      final device = remote.device;
      final owner = remote.connection.controller;
      if (device == null) {
        return;
      }
      final minutes =
          int.tryParse(context.settings['minutes'] ?? '')?.clamp(1, 180) ?? 30;
      final confirmed = await ConfirmationDialog.ask(
        context.buildContext!,
        title: 'Turn off in $minutes minutes?',
        confirmLabel: 'Start timer',
        message: 'Keep this app running and connected to this device. Background suspension can delay the local timer.',
      );
      if (!confirmed ||
          remote.device?.id != device.id ||
          !identical(remote.connection.controller, owner)) {
        return;
      }
      remote.scheduleSleep(device, Duration(minutes: minutes));
    },
  ),
);

final wakeAction = RemoteAction<RemotePanel>(
  'wake',
  usableOffline: true,
  builder: (context, remote) => (
    icon: Icons.power,
    label: 'Wake device',
    enabled: remote.canWake,
    execute: remote.wake,
  ),
);

final connectAction = RemoteAction<RemotePanel>(
  'connect',
  usableOffline: true,
  builder: (context, remote) => (
    icon: remote.offline ? Icons.link : Icons.link_off,
    label: remote.offline ? 'Connect' : 'Disconnect',
    enabled: true,
    execute: () => remote.offline ? remote.retry() : remote.disconnect(),
  ),
);

final detailsAction = RemoteAction<RemotePanel>(
  'details',
  usableOffline: true,
  builder: (context, remote) => (
    icon: Icons.info_outline,
    label: 'View details',
    enabled: true,
    execute: () => remote.showDeviceDetails(context.buildContext!),
  ),
);

final deviceSwitchAction = RemoteAction<RemotePanel>(
  'device_switcher',
  usableOffline: true,
  builder: (context, remote) => (
    icon: Icons.tv,
    label: 'Switch TV',
    enabled: true,
    execute: () => remote.switchDevice(context.buildContext!),
  ),
);

final connectionInfo = RemoteInfo<RemotePanel>(
  'connection',
  icon: (_) => Icons.link,
  read: (context) => RemoteReading(context.remote.status),
);

final deviceNameInfo = RemoteInfo<RemotePanel>(
  'device_name',
  icon: (_) => Icons.devices,
  read: (context) => RemoteReading(context.remote.displayName),
);

/// Reads the address straight from the stored device profile.
final deviceAddressInfo = RemoteInfo<RemotePanel>(
  'device_address',
  icon: (_) => Icons.lan_outlined,
  read: (context) => RemoteReading(
    context.device?.endpoints.firstOrNull?.host ?? 'No address saved',
  ),
);

final standardItemDefinitions = <RemoteItemDefinition<Object>>[
  RemoteItemDefinition(
    'power',
    'Power off',
    RemoteItemCategory.utilities,
    settings: [
      RemoteSetting.toggle('confirm', 'Ask before turning off', enabled: true),
    ],
    requires: const {RemoteCapability.power},
    elements: [powerOffAction],
  ),
  RemoteItemDefinition(
    'sleep',
    'Sleep timer',
    RemoteItemCategory.utilities,
    settings: [
      RemoteSetting.number(
        'minutes',
        'Turn off after this many minutes',
        minimum: 1,
        maximum: 180,
        initial: 30,
      ),
    ],
    requires: const {RemoteCapability.power},
    elements: [sleepTimerAction],
  ),
  RemoteItemDefinition<RemotePanel>(
    'connection',
    'Connection status',
    RemoteItemCategory.information,
    elements: [connectionInfo],
  ),
  RemoteItemDefinition<RemotePanel>(
    'deviceName',
    'Device name',
    RemoteItemCategory.information,
    layout: LinearLayout(size: RemoteItemSize(2, 1)),
    elements: [deviceNameInfo],
  ),
  RemoteItemDefinition<RemotePanel>(
    'deviceAddress',
    'IP address',
    RemoteItemCategory.information,
    description: 'Show the network address saved for this device.',
    elements: [deviceAddressInfo],
  ),
  RemoteItemDefinition<RemotePanel>(
    'deviceSwitcher',
    'Switch TV',
    RemoteItemCategory.information,
    elements: [deviceSwitchAction],
  ),
  RemoteItemDefinition<RemotePanel>(
    'wake',
    'Wake device',
    RemoteItemCategory.utilities,
    requires: {RemoteCapability.wake},
    elements: [wakeAction],
  ),
  RemoteItemDefinition<RemotePanel>(
    'connect',
    'Connect or disconnect',
    RemoteItemCategory.utilities,
    elements: [connectAction],
  ),
  RemoteItemDefinition<RemotePanel>(
    'details',
    'Device details',
    RemoteItemCategory.utilities,
    elements: [detailsAction],
  ),
  const RemoteItemDefinition<RemotePanel>(
    'group',
    'Custom group',
    RemoteItemCategory.groups,
    settings: [RemoteSetting.toggle('showTitle', 'Show group name')],
    layout: GroupLayout(
      size: RemoteItemSize(4, 3, minimumWidth: 1, minimumHeight: 1),
    ),
    description:
        'Arrange multiple controls together in a single customizable area.',
  ),
  const RemoteItemDefinition<RemotePanel>(
    'spacer',
    'Empty space',
    RemoteItemCategory.groups,
    layout: EmptyLayout(),
  ),
  const RemoteItemDefinition<RemotePanel>(
    'unknown',
    'Unavailable control',
    RemoteItemCategory.utilities,
    layout: UnavailableLayout(),
  ),
];
