import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewports/settings_viewport.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key, required AppDependencies dependencies})
    : model = SettingsViewModel(dependencies);
  final SettingsViewModel model;
  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: model.changes, builder: _content);
  Widget _content(BuildContext context, Widget? child) =>
      SettingsViewport(model: model);
}
