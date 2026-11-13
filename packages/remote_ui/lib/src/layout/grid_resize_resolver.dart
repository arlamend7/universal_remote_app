import 'dart:math' as math;

import '../definitions/remote_item_definition.dart';
import '../definitions/remote_item_registry.dart';
import 'grid_geometry.dart';
import 'models/grid_item.dart';
import 'models/grid_layout.dart';

/// Turns a requested size into the nearest valid footprint on one page (or
/// group). Shared by the nine-dot handle, the Edit Control sheet and Position
/// changes, so minimums, bounds and collisions are checked in one place.
///
/// It never changes anything while it searches, never moves other items,
/// never adds rows or columns, and never changes the item's Position.
abstract final class GridResizeResolver {
  /// [item] at [width] by [height], or the closest valid alternative:
  ///
  /// 1. the size clamped to the item's effective minimum and the page;
  /// 2. at the item's current place, if it fits there;
  /// 3. otherwise at the nearest free slot for that size;
  /// 4. otherwise (with [shrinkToFit]) the closest smaller size that fits,
  ///    never below the minimum, in place or at its nearest free slot.
  ///
  /// [item] and [others] use page coordinates. Null when nothing is valid.
  static GridItem? resolve(
    GridItem item,
    int width,
    int height,
    List<GridItem> others, {
    required int columns,
    required int rows,
    int startRow = 0,
    bool shrinkToFit = true,
  }) {
    final page = (columns: columns, rows: rows, startRow: startRow);
    final minimum = item.minimumSize;
    final maximumWidth = math.min(columns, GridLayout.maxColumns);
    final maximumHeight = math.min(
      rows - startRow,
      RemoteItemDefinition.maximumHeight,
    );
    final requested = item.copy(
      w: _within(width, minimum.width, maximumWidth),
      h: _within(height, minimum.height, maximumHeight),
    );
    final exact = _place(requested, others, page);
    if (exact != null || !shrinkToFit) {
      return exact;
    }
    return _smaller(requested, minimum, others, page);
  }

  static GridItem? _place(
    GridItem item,
    List<GridItem> others,
    ({int columns, int rows, int startRow}) page,
  ) {
    final inPlace =
        item.y >= page.startRow &&
        GridGeometry.fits(item, others, columns: page.columns, rows: page.rows);
    if (inPlace) {
      return item;
    }
    return GridGeometry.nearest(
      item,
      others,
      columns: page.columns,
      rows: page.rows,
      startRow: page.startRow,
    );
  }

  /// Smaller sizes from closest to the request (then larger area first).
  static GridItem? _smaller(
    GridItem requested,
    ({int width, int height}) minimum,
    List<GridItem> others,
    ({int columns, int rows, int startRow}) page,
  ) {
    final sizes = [
      for (var w = requested.w; w >= minimum.width; w--)
        for (var h = requested.h; h >= minimum.height; h--) (w: w, h: h),
    ]..sort((a, b) => _order(requested, a, b));
    for (final size in sizes) {
      final placed = _place(requested.copy(w: size.w, h: size.h), others, page);
      if (placed != null) {
        return placed;
      }
    }
    return null;
  }

  static int _order(
    GridItem requested,
    ({int w, int h}) a,
    ({int w, int h}) b,
  ) {
    final distance = _shrink(requested, a).compareTo(_shrink(requested, b));
    if (distance != 0) {
      return distance;
    }
    return (b.w * b.h).compareTo(a.w * a.h);
  }

  static int _shrink(GridItem requested, ({int w, int h}) size) =>
      (requested.w - size.w) + (requested.h - size.h);

  /// Never below [minimum], even when the page has less room.
  static int _within(int value, int minimum, int maximum) =>
      value.clamp(minimum, math.max(minimum, maximum));
}
