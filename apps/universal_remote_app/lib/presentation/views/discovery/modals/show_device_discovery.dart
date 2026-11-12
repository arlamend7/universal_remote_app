import 'package:flutter/material.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';
import '../../devices/modals/edit_device.dart';
import 'device_discovery_sheet.dart';
import 'device_preparation_sheet.dart';

Future<RemoteDevice?> showDeviceDiscovery(
  BuildContext context,
  AppDependencies dependencies,
) async {
  final search = await showAppModal<bool>(
    context,
    builder: (_) => const DevicePreparationSheet(),
  );
  if (search == null || !context.mounted) {
    return null;
  }
  if (!search) {
    return editDevice(context, dependencies);
  }
  return showAppModal<RemoteDevice>(
    context,
    builder: (_) => DeviceDiscoverySheet(dependencies: dependencies),
  );
}
