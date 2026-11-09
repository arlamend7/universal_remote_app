import 'package:flutter/material.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';
import 'device_discovery_sheet.dart';

Future<RemoteDevice?> showDeviceDiscovery(
  BuildContext context,
  AppDependencies dependencies,
) => showAppModal<RemoteDevice>(
  context,
  builder: (_) => DeviceDiscoverySheet(dependencies: dependencies),
);
