import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../app/app_dependencies.dart';
import '../presentation/views/remote/viewmodels/remote_viewmodel.dart';

import 'package:remote_ui/remote_ui.dart';

Future<void> openRemoteEditor(
  BuildContext context,
  AppDependencies dependencies,
  RemoteDevice device, {
  GridEditorViewModel? parent,
  GridItem? group,
}) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => GridEditorPage(
      dependencies: RemoteEditorHost(
        grids: dependencies.grids,
        live: RemoteViewModel(dependencies),
        canWakeDevice: dependencies.canWakeDevice,
      ),
      device: device,
      parent: parent,
      group: group,
    ),
  ),
);
