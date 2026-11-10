import 'package:flutter/material.dart';

import '../../layout/models/grid_item.dart';
import '../../layout/models/square_grid_metrics.dart';

final class GridEditorPageGeometry {
  const GridEditorPageGeometry({
    required this.start,
    required this.columns,
    required this.rows,
    required this.left,
    required this.side,
  });

  final int start, columns, rows;
  final double left, side;

  double get stride => side + SquareGridMetrics.gap;
  double get end => left + columns * stride;
  double get height => SquareGridMetrics.extent(rows, side);
  bool contains(int column) => column >= start && column < start + columns;

  Rect rect(GridItem item) => Rect.fromLTWH(
    left + (item.x - start) * stride,
    item.y * stride,
    SquareGridMetrics.extent(item.w, side),
    SquareGridMetrics.extent(item.h, side),
  );
}
