import 'package:remote_ui/src/ui_model.dart';
import 'package:flutter/material.dart';

import 'widget_library_state.dart';

class WidgetLibrarySheet extends StatefulWidget {
  const WidgetLibrarySheet({
    super.key,
    required this.model,
    required this.dependencies,
    required this.insideGroup,
  });
  final GridEditorViewModel model;
  final RemoteEditorHost dependencies;
  final bool insideGroup;
  @override
  State<WidgetLibrarySheet> createState() => WidgetLibraryState();
}
