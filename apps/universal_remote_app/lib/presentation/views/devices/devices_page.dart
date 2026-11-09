import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../app/app_dependencies.dart';
import 'viewmodels/devices_viewmodel.dart';
import 'viewports/devices_viewport.dart';

class DevicesPage extends StatelessWidget {
  DevicesPage({
    super.key,
    required AppDependencies dependencies,
    required void Function(RemoteDevice) onConnect,
    required void Function(RemoteDevice) onWake,
  }) : model = DevicesViewModel(
         dependencies,
         onConnect: onConnect,
         onWake: onWake,
       );
  final DevicesViewModel model;
  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: model.changes, builder: _content);
  Widget _content(BuildContext context, Widget? child) =>
      DevicesViewport(model: model);
}
