import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';
import '../../../shared/widgets/setup/push_setup_page.dart';
import 'device_pairing_page.dart';
import 'show_supported_remote_items.dart';

Future<RemoteDevice?> showDevicePairing(
  BuildContext context,
  AppDependencies dependencies,
  RemoteDevice device,
) async {
  final connection = dependencies.connection;
  final previousAttempt = connection.attempt;
  final connected = await pushSetupPage<RemoteDevice>(
    context,
    DevicePairingPage(dependencies: dependencies, device: device),
  );
  if (connected == null) {
    if (connection.attempt != previousAttempt &&
        connection.selected.value?.id == device.id &&
        connection.state.value != DeviceConnectionState.connected) {
      await connection.disconnect();
    }
    return null;
  }
  if (!context.mounted) {
    return null;
  }
  final openRemote = await showSupportedRemoteItems(
    context,
    dependencies,
    connected,
  );
  return openRemote ? connected : null;
}
