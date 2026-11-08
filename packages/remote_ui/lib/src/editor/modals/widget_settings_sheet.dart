import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import 'widget_settings_state.dart';

class WidgetSettingsSheet extends StatefulWidget {
  const WidgetSettingsSheet({
    super.key,
    required this.item,
    required this.model,
    required this.dependencies,
    this.onEditGroup,
  });
  final GridItem item;
  final GridEditorViewModel model;
  final RemoteEditorHost dependencies;
  final VoidCallback? onEditGroup;
  @override
  State<WidgetSettingsSheet> createState() => WidgetSettingsState();
}
