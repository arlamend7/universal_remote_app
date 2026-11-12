import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

import '../../../../app/app_dependencies.dart';
import 'device_pairing_sheet.dart';

Future<RemoteDevice?> showDevicePairing(
  BuildContext context,
  AppDependencies dependencies,
  RemoteDevice device,
) async {
  final connected = await showAppModal<RemoteDevice>(
    context,
    isDismissible: false,
    enableDrag: false,
    builder: (_) =>
        DevicePairingSheet(dependencies: dependencies, device: device),
  );
  if (connected == null &&
      dependencies.connection.selected.value?.id == device.id) {
    await dependencies.connection.disconnect();
  }
  return connected;
}
