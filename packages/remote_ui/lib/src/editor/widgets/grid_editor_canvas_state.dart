import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../../widgets/grid/grid_surface.dart';
import 'grid_edit_tile.dart';
import 'grid_editor_canvas.dart';
import 'grid_lines_painter.dart';

class GridEditorCanvasState extends State<GridEditorCanvas> {
  final target = GlobalKey();
  GridItem? ghost;
  double cellWidth = 0, cellHeight = 0;
  int get rows {
    final occupied = widget.model.draft.items.fold<int>(
      0,
      (last, item) => math.max(last, item.y + item.h),
    );
    return math.min(
      widget.model.maxRows,
      math.max(4, occupied + 2) + widget.model.extraRows,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _layout);
  Widget _layout(BuildContext context, BoxConstraints constraints) {
    cellWidth =
        (constraints.maxWidth - (widget.model.columns - 1) * 8) /
        widget.model.columns;
    cellHeight = math.max(
      cellWidth,
      64 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
    );
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => !widget.model.saving,
      onMove: _move,
      onLeave: (_) => setState(() => ghost = null),
      onAcceptWithDetails: _accept,
      builder: (_, candidate, rejected) => _canvas(context),
    );
  }

  Widget _canvas(BuildContext context) => SizedBox(
    key: target,
    height: rows * (cellHeight + 8) - 8,
    child: Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: GridLinesPainter(
              columns: widget.model.columns,
              rows: rows,
              cellWidth: cellWidth,
              cellHeight: cellHeight,
              color: Theme.of(context).dividerColor,
            ),
          ),
        ),
        GridSurface(
          layout: widget.model.draft,
          columns: widget.model.columns,
          rows: rows,
          cellHeight: cellHeight,
          itemBuilder: (item) => GridEditTile(
            item: item,
            model: widget.model,
            dependencies: widget.dependencies,
            onEdit: widget.onEdit,
          ),
        ),
        if (ghost != null) _ghost(context, ghost!),
      ],
    ),
  );
  Widget _ghost(BuildContext context, GridItem item) => Positioned(
    left: item.x * (cellWidth + 8),
    top: item.y * (cellHeight + 8),
    width: item.w * (cellWidth + 8) - 8,
    height: item.h * (cellHeight + 8) - 8,
    child: IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            width: 3,
            color:
                GridArrangement.replace(
                      widget.model.draft,
                      item,
                      columns: widget.model.columns,
                      rows: widget.model.maxRows,
                      reservedRows: widget.model.reservedRows,
                    ) !=
                    null
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
  GridItem? _candidate(String id, Offset offset) {
    final item = widget.model.draft.items
        .where((item) => item.id == id)
        .firstOrNull;
    final box = target.currentContext?.findRenderObject() as RenderBox?;
    if (item == null || box == null) {
      return null;
    }
    final local = box.globalToLocal(offset);
    return item.copy(
      x: (local.dx / (cellWidth + 8)).round().clamp(
        0,
        widget.model.columns - item.w,
      ),
      y: (local.dy / (cellHeight + 8)).round().clamp(
        widget.model.reservedRows,
        widget.model.maxRows - item.h,
      ),
    );
  }

  void _move(DragTargetDetails<String> details) =>
      setState(() => ghost = _candidate(details.data, details.offset));
  void _accept(DragTargetDetails<String> details) {
    final item = _candidate(details.data, details.offset);
    setState(() => ghost = null);
    if (item != null) {
      widget.model.replace(item);
    }
  }
}
