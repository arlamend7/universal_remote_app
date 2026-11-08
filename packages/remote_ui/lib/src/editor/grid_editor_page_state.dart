import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import 'widgets/grid_editor_content.dart';
import 'grid_editor_page.dart';

class GridEditorPageState extends State<GridEditorPage> {
  late final model = GridEditorViewModel(
    widget.dependencies.grids,
    widget.device,
    initial: widget.group == null ? null : GridLayout(widget.group!.children),
    columns: widget.group?.w ?? 4,
    maxRows: widget.group?.h ?? 128,
    reservedRows: widget.group?.config['showTitle'] == 'true' ? 1 : 0,
  );
  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (_, child) => GridEditorContent(
      model: model,
      dependencies: widget.dependencies,
      parent: widget.parent,
      group: widget.group,
    ),
  );
}
