import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import 'grid_surface.dart';
import 'models/grid_viewport_metrics.dart';

class FittedGridSurface extends StatelessWidget {
  const FittedGridSurface({
    super.key,
    required this.layout,
    required this.itemBuilder,
    this.columns = 4,
    this.rows,
  });
  final GridLayout layout;
  final Widget Function(GridItem) itemBuilder;
  final int columns;
  final int? rows;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _fit);
  Widget _fit(BuildContext context, BoxConstraints constraints) {
    final count = rows ?? layout.occupiedRows;
    final metrics = GridViewportMetrics(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      columns: columns,
      rows: count,
      items: layout.items,
      textScale: MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
    );
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: metrics.worldWidth,
          height: metrics.worldHeight,
          child: GridSurface(
            layout: layout,
            columns: columns,
            rows: count,
            cellHeight: metrics.cellHeight,
            itemBuilder: itemBuilder,
          ),
        ),
      ),
    );
  }
}
