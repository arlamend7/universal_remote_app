import 'package:flutter/material.dart';

import '../../layout/models/grid_item.dart';
import '../../layout/models/grid_layout.dart';
import '../../layout/models/square_grid_metrics.dart';
import 'grid_surface.dart';

class SquareGridSurface extends StatelessWidget {
  const SquareGridSurface({
    super.key,
    required this.layout,
    required this.columns,
    this.columnOffset = 0,
    required this.rows,
    required this.itemBuilder,
    this.onHorizontalOverflow,
    this.allowsPageGesture,
  });

  final GridLayout layout;
  final ValueChanged<int>? onHorizontalOverflow;
  final bool Function()? allowsPageGesture;
  final int columns, columnOffset, rows;
  final Widget Function(GridItem) itemBuilder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _layout);

  Widget _layout(BuildContext context, BoxConstraints constraints) {
    final side = layout.cellSize;
    final width = SquareGridMetrics.extent(columns, side);
    final height = SquareGridMetrics.extent(rows, side);
    Widget content = SizedBox(
      width: width,
      child: GridSurface(
        layout: layout,
        columns: columns,
        rows: rows,
        columnOffset: columnOffset,
        cellHeight: side,

        itemBuilder: itemBuilder,
      ),
    );
    if (height > constraints.maxHeight + .001) {
      content = SingleChildScrollView(child: content);
    }
    if (width > constraints.maxWidth + .001) {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: onHorizontalOverflow == null
            ? null
            : const ClampingScrollPhysics(),
        child: content,
      );
    }
    return Align(alignment: Alignment.topLeft, child: _handleOverflow(content));
  }

  Widget _handleOverflow(Widget child) {
    final callback = onHorizontalOverflow;
    if (callback == null) {
      return child;
    }
    var overscroll = 0.0;
    return NotificationListener<ScrollNotification>(
      onNotification: (event) {
        if (event.metrics.axis != Axis.horizontal) {
          return false;
        }
        if (event is ScrollStartNotification) {
          overscroll = 0;
        }
        if (event is OverscrollNotification &&
            event.dragDetails != null &&
            (allowsPageGesture?.call() ?? true)) {
          overscroll += event.overscroll;
        }
        if (event is ScrollEndNotification && overscroll.abs() >= 36) {
          callback(overscroll > 0 ? 1 : -1);
          overscroll = 0;
        }
        return false;
      },
      child: child,
    );
  }
}
