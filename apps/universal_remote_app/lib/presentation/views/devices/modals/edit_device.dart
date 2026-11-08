import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';
import 'device_editor.dart';

Future<RemoteDevice?> editDevice(
  BuildContext context,
  AppDependencies dependencies, {
  RemoteDevice? device,
}) => showModalBottomSheet<RemoteDevice>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 600),
  builder: (_) => DeviceEditor(dependencies: dependencies, device: device),
);
