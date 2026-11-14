import 'package:flutter/material.dart';

import '../../drivers/driver_explorer_page.dart';
import '../viewmodels/settings_viewmodel.dart';
import 'driver_settings_tile_state.dart';

class DriverSettingsTile extends StatefulWidget {
  const DriverSettingsTile({
    super.key,
    required this.model,
    required this.icon,
  });

  final SettingsViewModel model;
  final Widget icon;

  @override
  State<DriverSettingsTile> createState() => DriverSettingsTileState();

  void openExplorer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DriverExplorerPage(drivers: model.dependencies.drivers),
      ),
    );
  }
}
