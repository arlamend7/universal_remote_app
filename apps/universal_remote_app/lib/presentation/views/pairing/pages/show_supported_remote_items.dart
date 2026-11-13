import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../routes/open_remote_editor.dart';
import '../../../shared/widgets/setup/push_setup_page.dart';
import '../../devices/widgets/setup_device_row.dart';
import '../../../shared/widgets/setup/setup_step_page.dart';
import '../../devices/modals/show_device_details.dart';
import '../../remote/viewmodels/remote_viewmodel.dart';
import '../widgets/supported_remote_items.dart';

Future<bool> showSupportedRemoteItems(
  BuildContext context,
  AppDependencies dependencies,
  RemoteDevice device,
) async {
  final openRemote = await pushSetupPage<bool>(
    context,
    _overview(dependencies, device),
  );
  return openRemote ?? false;
}

Widget _overview(AppDependencies dependencies, RemoteDevice device) {
  final remote = RemoteViewModel(dependencies);
  return ListenableBuilder(
    listenable: remote.controlsChanges,
    builder: (context, _) => SetupStepPage(
      step: 4,
      title: 'Supported controls',
      banner: SetupDeviceRow(
        device: device,
        subtitle: [
          ?dependencies.providers.manualSetups[device.providerId]?.label ??
              device.manufacturer,
          ?device.model,
        ].join(' · '),
        connected: remote.state == DeviceConnectionState.connected,
      ),
      body: SupportedRemoteItems(remote: remote),
      secondary: OutlinedButton(
        onPressed: () => _customize(context, dependencies, device),
        child: const Text('Customize remote'),
      ),
      primary: FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Start controlling'),
      ),
      footerLink: TextButton(
        onPressed: () async {
          final customize = await showDeviceDetails(
            context,
            dependencies,
            device,
          );
          if (customize && context.mounted) {
            await _customize(context, dependencies, device);
          }
        },
        child: const Text('Device details'),
      ),
    ),
  );
}

Future<void> _customize(
  BuildContext context,
  AppDependencies dependencies,
  RemoteDevice device,
) async {
  final overview = ModalRoute.of(context);
  if (overview?.isCurrent != true) {
    return;
  }
  await openRemoteEditor(context, dependencies, device);
  if (context.mounted && overview?.isCurrent == true) {
    Navigator.pop(context, true);
  }
}
