import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';
import '../../../shared/widgets/setup/push_setup_page.dart';
import 'device_preparation_page.dart';

Future<RemoteDevice?> showDeviceDiscovery(
  BuildContext context,
  AppDependencies dependencies,
) => pushSetupPage<RemoteDevice>(
  context,
  DevicePreparationPage(dependencies: dependencies),
);
