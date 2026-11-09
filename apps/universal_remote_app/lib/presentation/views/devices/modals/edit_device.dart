import 'package:flutter/material.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';
import 'device_editor.dart';

Future<RemoteDevice?> editDevice(
  BuildContext context,
  AppDependencies dependencies, {
  RemoteDevice? device,
}) => showAppModal<RemoteDevice>(
  context,
  builder: (_) => DeviceEditor(dependencies: dependencies, device: device),
);
