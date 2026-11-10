import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import 'widgets/grid_editor_content.dart';
import 'grid_editor_page.dart';

class GridEditorPageState extends State<GridEditorPage> {
  late final _horizontal = ScrollController(onAttach: _restorePage);
  final _viewport = GlobalKey();
  late final model = GridEditorViewModel(
    widget.dependencies.grids,
    widget.device,
    initial: widget.group == null ? null : GridLayout(widget.group!.children),
    columns: widget.group?.w,
    maxRows: widget.group?.h,
    reservedRows: widget.group?.config['showTitle'] == 'true' ? 1 : 0,
  );
  void _restorePage(ScrollPosition position) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_horizontal.positions.contains(position) ||
          !position.hasContentDimensions ||
          model.pageStart == 0) {
        return;
      }
      final offset = model.draft.pageOffset(
        model.draft.pageIndexAt(model.pageStart),
      );
      position.jumpTo(offset.clamp(0.0, position.maxScrollExtent));
    });
  }

  @override
  void dispose() {
    _horizontal.dispose();
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (_, child) => GridEditorContent(
      model: model,
      viewport: _viewport,
      horizontal: _horizontal,
      dependencies: widget.dependencies,
      parent: widget.parent,
      group: widget.group,
    ),
  );
}
