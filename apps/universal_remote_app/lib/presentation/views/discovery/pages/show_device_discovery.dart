import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';
import '../../../shared/widgets/setup/push_setup_page.dart';
import 'device_preparation_page.dart';

/// Opens setup from the app shell.
///
/// Searching replaces the preparation step, so Back on the discovery step
/// returns to the page that opened setup. The discovery result is forwarded.
Future<RemoteDevice?> showDeviceDiscovery(
  BuildContext context,
  AppDependencies dependencies,
) async {
  Future<RemoteDevice?>? discovery;
  final device = await pushSetupPage<RemoteDevice>(
    context,
    DevicePreparationPage(
      dependencies: dependencies,
      onReplacedByDiscovery: (selection) => discovery = selection,
    ),
  );
  return device ?? await discovery;
}
