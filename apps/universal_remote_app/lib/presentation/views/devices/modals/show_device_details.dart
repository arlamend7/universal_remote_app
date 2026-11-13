import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';

import 'package:remote_ui/remote_ui.dart';

import '../viewmodels/device_details_viewmodel.dart';
import '../widgets/device_details_content.dart';

Future<bool> showDeviceDetails(
  BuildContext context,
  AppDependencies dependencies,
  RemoteDevice device,
) async =>
    await showAppModal<bool>(
      context,
      builder: (sheetContext) => AppSheet(
        title: 'Device info',
        child: DeviceDetailsContent(
          model: DeviceDetailsViewModel(dependencies, device),
          onCustomize: () => Navigator.pop(sheetContext, true),
        ),
      ),
    ) ??
    false;
