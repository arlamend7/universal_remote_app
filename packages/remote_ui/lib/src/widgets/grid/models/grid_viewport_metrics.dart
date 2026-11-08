import 'dart:math' as math;

import 'package:remote_ui/src/ui_model.dart';

/// Keeps renderer minimums intact before fitting unusually dense layouts.
final class GridViewportMetrics {
  GridViewportMetrics({
    required double width,
    required double height,
    required int columns,
    required int rows,
    required List<GridItem> items,
    required double textScale,
    double gap = 8,
  }) {
    worldWidth = math.max(width, columns * 72 + (columns - 1) * gap);
    final cellWidth = (worldWidth - (columns - 1) * gap) / columns;
    final widthScale = math.min(1.0, width / worldWidth);
    final base = math.max(48.0, 32 * textScale + 8);
    final minimum = items.fold<double>(
      base,
      (last, item) => math.max(last, _minimum(item, cellWidth, gap, base)),
    );
    final available = (height / widthScale - (rows - 1) * gap) / rows;
    cellHeight = available.clamp(minimum, math.max(minimum, cellWidth));
    worldHeight = rows * cellHeight + (rows - 1) * gap;
  }
  late final double worldWidth, worldHeight, cellHeight;
  static double _minimum(
    GridItem item,
    double cellWidth,
    double gap,
    double base,
  ) {
    if (item.isGroup) {
      return item.children.fold<double>(
        base,
        (last, child) => math.max(last, _minimum(child, cellWidth, gap, base)),
      );
    }
    final needed = item.definition.layout.minimumHeight(
      width: item.w,
      cellWidth: cellWidth,
      gap: gap,
      settings: item.config,
    );
    return math.max(base, (needed - (item.h - 1) * gap) / item.h);
  }
}
