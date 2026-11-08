import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter/material.dart' show Icons;
import 'package:remote_core/remote_core.dart';

import '../elements/remote_action.dart';
import '../elements/remote_info.dart';
import '../elements/remote_reading.dart';
import '../host/remote_panel.dart';
import '../definitions/enums/remote_item_category.dart';
import '../definitions/remote_item_definition.dart';
import '../layout/models/enums/grid_widget_kind.dart';

final powerOffAction = RemoteAction<RemotePanel, Null>(
  'power_off',
  icon: (_) => Icons.power_settings_new,
  onPressed: (remote, _) => remote.connection.powerOff(),
);

final sleepTimerAction = RemoteAction<RemotePanel, Duration?>(
  'sleep_timer',
  icon: (_) => Icons.bedtime_outlined,
  slots: 2,
  onPressed: (remote, duration) async {
    if (duration == null) {
      remote.cancelSleep();
      return;
    }
    final device = remote.device;
    if (device != null) {
      remote.scheduleSleep(device, duration);
    }
  },
);

final wakeAction = RemoteAction<RemotePanel, Null>(
  'wake',
  icon: (_) => Icons.power,
  onPressed: (remote, _) => remote.wake(),
);

final connectAction = RemoteAction<RemotePanel, Null>(
  'connect',
  icon: (context) => context.remote.offline ? Icons.link : Icons.link_off,
  onPressed: (remote, _) =>
      remote.offline ? remote.retry() : remote.disconnect(),
);

final detailsAction = RemoteAction<RemotePanel, BuildContext>(
  'details',
  icon: (_) => Icons.info_outline,
  onPressed: (remote, context) => remote.showDeviceDetails(context),
);

final deviceSwitchAction = RemoteAction<RemotePanel, BuildContext>(
  'device_switcher',
  icon: (_) => Icons.tv,
  onPressed: (remote, context) => remote.switchDevice(context),
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
    GridWidgetKind.power,
    'Power off',
    RemoteItemCategory.utilities,
    requires: const {RemoteCapability.power},
    elements: [powerOffAction],
  ),
  RemoteItemDefinition(
    GridWidgetKind.sleep,
    'Sleep timer',
    RemoteItemCategory.utilities,
    requires: const {RemoteCapability.power},
    elements: [sleepTimerAction],
  ),
  RemoteItemDefinition<RemotePanel>(
    GridWidgetKind.connection,
    'Connection status',
    RemoteItemCategory.information,
    elements: [connectionInfo],
  ),
  RemoteItemDefinition<RemotePanel>(
    GridWidgetKind.deviceName,
    'Device name',
    RemoteItemCategory.information,
    elements: [deviceNameInfo],
  ),
  RemoteItemDefinition<RemotePanel>(
    GridWidgetKind.deviceAddress,
    'IP address',
    RemoteItemCategory.information,
    description: 'Show the network address saved for this device.',
    elements: [deviceAddressInfo],
  ),
  RemoteItemDefinition<RemotePanel>(
    GridWidgetKind.deviceSwitcher,
    'Switch TV',
    RemoteItemCategory.information,
    elements: [deviceSwitchAction],
  ),
  RemoteItemDefinition<RemotePanel>(
    GridWidgetKind.wake,
    'Wake device',
    RemoteItemCategory.utilities,
    requires: {RemoteCapability.wake},
    elements: [wakeAction],
  ),
  RemoteItemDefinition<RemotePanel>(
    GridWidgetKind.connect,
    'Connect or disconnect',
    RemoteItemCategory.utilities,
    elements: [connectAction],
  ),
  RemoteItemDefinition<RemotePanel>(
    GridWidgetKind.details,
    'Device details',
    RemoteItemCategory.utilities,
    elements: [detailsAction],
  ),
  const RemoteItemDefinition<RemotePanel>(
    GridWidgetKind.group,
    'Custom group',
    RemoteItemCategory.groups,
    description:
        'Arrange multiple controls together in a single customizable area.',
  ),
  const RemoteItemDefinition<RemotePanel>(
    GridWidgetKind.spacer,
    'Empty space',
    RemoteItemCategory.groups,
  ),
  const RemoteItemDefinition<RemotePanel>(
    GridWidgetKind.unknown,
    'Unavailable control',
    RemoteItemCategory.utilities,
  ),
];
