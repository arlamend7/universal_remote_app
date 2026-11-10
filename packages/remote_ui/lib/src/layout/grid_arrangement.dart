import 'models/grid_item.dart';
import 'models/grid_layout.dart';
import 'grid_geometry.dart';

/// Replaces one control at its requested coordinates while preserving its neighbors.
abstract final class GridArrangement {
  static GridLayout? replace(
    GridLayout layout,
    GridItem replacement, {
    int columns = 4,
    int rows = 128,
    int reservedRows = 0,
  }) {
    if (replacement.y < reservedRows) {
      return null;
    }
    final next = layout.withItems(
      layout.items.map(
        (item) => item.id == replacement.id ? replacement : item,
      ),
    );
    return GridGeometry.valid(next.items, columns: columns, rows: rows)
        ? next
        : null;
  }
}
