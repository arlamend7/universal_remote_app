import 'package:flutter/material.dart';
import 'package:remote_ui/src/widgets/sheets/show_app_sheet.dart';

import 'device_choice_state.dart';

class DeviceChoiceSheet extends StatefulWidget {
  const DeviceChoiceSheet({
    super.key,
    required this.title,
    required this.choices,
    this.selectedId,
    this.grid = false,
  });
  final String title;
  final List<(String, String)> choices;
  final String? selectedId;

  /// Shows large icons with a search box instead of a plain list.
  final bool grid;
  static Future<String?> choose(
    BuildContext context,
    String title,
    List<(String, String)> choices, {
    String? selectedId,
    bool grid = false,
  }) => showAppModal<String>(
    context,
    builder: (_) => DeviceChoiceSheet(
      title: title,
      choices: choices,
      selectedId: selectedId,
      grid: grid,
    ),
  );
  @override
  State<DeviceChoiceSheet> createState() => DeviceChoiceState();
}
