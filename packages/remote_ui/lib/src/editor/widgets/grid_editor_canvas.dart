import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import 'grid_editor_canvas_state.dart';

class GridEditorCanvas extends StatefulWidget {
  const GridEditorCanvas({
    super.key,
    required this.model,
    this.dependencies,
    this.onEdit,
  });
  final GridEditorViewModel model;
  final RemoteEditorHost? dependencies;
  final ValueChanged<GridItem>? onEdit;
  @override
  State<GridEditorCanvas> createState() => GridEditorCanvasState();
}
