import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';

import 'package:remote_ui/remote_ui.dart';

import '../viewmodels/device_details_viewmodel.dart';
import '../widgets/device_details_content.dart';

Future<void> showDeviceDetails(
  BuildContext context,
  AppDependencies dependencies,
  RemoteDevice device,
) => showAppSheet<void>(
  context,
  title: 'Device info',
  child: DeviceDetailsContent(
    model: DeviceDetailsViewModel(dependencies, device),
  ),
);
