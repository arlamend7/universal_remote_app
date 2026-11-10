import 'models/grid_item.dart';
import '../definitions/remote_item_registry.dart';

abstract final class GridGeometry {
  static bool overlaps(GridItem a, GridItem b) =>
      a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
  static bool fits(
    GridItem item,
    List<GridItem> items, {
    int columns = 4,
    int rows = 128,
  }) {
    if (item.x < 0 ||
        item.y < 0 ||
        item.x + item.w > columns ||
        item.y + item.h > rows ||
        item.quarterTurns < 0 ||
        item.quarterTurns > 3 ||
        !item.definition.accepts(item.contentWidth, item.contentHeight)) {
      return false;
    }
    return !items.any((other) => other.id != item.id && overlaps(item, other));
  }

  static GridItem? place(
    GridItem item,
    List<GridItem> items, {
    int columns = 4,
    int rows = 128,
    int startRow = 0,
    bool Function(GridItem)? accepts,
  }) {
    for (var y = startRow; y <= rows - item.h; y++) {
      final placed = _row(item, items, y, columns, rows, accepts);
      if (placed != null) {
        return placed;
      }
    }
    return null;
  }

  static GridItem? _row(
    GridItem item,
    List<GridItem> items,
    int y,
    int columns,
    int rows,
    bool Function(GridItem)? accepts,
  ) {
    for (var x = 0; x <= columns - item.w; x++) {
      final placed = item.copy(x: x, y: y);
      if ((accepts?.call(placed) ?? true) &&
          fits(placed, items, columns: columns, rows: rows)) {
        return placed;
      }
    }
    return null;
  }

  static bool valid(
    List<GridItem> items, {
    int columns = 4,
    int rows = 128,
    bool insideGroup = false,
  }) {
    final ids = items.map((item) => item.id).toSet();
    if (ids.length != items.length || items.length > 128) {
      return false;
    }
    return items.every(
      (item) => _validItem(item, items, columns, rows, insideGroup),
    );
  }

  static bool _validItem(
    GridItem item,
    List<GridItem> items,
    int columns,
    int rows,
    bool insideGroup,
  ) {
    if (item.id.isEmpty || !fits(item, items, columns: columns, rows: rows)) {
      return false;
    }
    if (item.isUnavailable) {
      return true;
    }
    if (!item.isGroup) {
      return item.children.isEmpty;
    }
    if (item.quarterTurns != 0) {
      return false;
    }
    if (item.config['showTitle'] == 'true' &&
        item.children.any((child) => child.y == 0)) {
      return false;
    }
    return !insideGroup &&
        valid(item.children, columns: item.w, rows: item.h, insideGroup: true);
  }
}
