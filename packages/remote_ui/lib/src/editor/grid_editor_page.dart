import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/src/ui_model.dart';

import 'grid_editor_page_state.dart';

class GridEditorPage extends StatefulWidget {
  const GridEditorPage({
    super.key,
    required this.dependencies,
    required this.device,
    this.parent,
    this.group,
  });
  final RemoteEditorHost dependencies;
  final RemoteDevice device;
  final GridEditorViewModel? parent;
  final GridItem? group;
  @override
  State<GridEditorPage> createState() => GridEditorPageState();
}
