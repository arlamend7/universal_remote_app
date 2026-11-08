import 'models/grid_item.dart';
import 'models/grid_layout.dart';
import 'grid_geometry.dart';

/// Resizing keeps the chosen item anchored and moves only controls in its way.
abstract final class GridArrangement {
  static GridLayout? replace(
    GridLayout layout,
    GridItem replacement, {
    int columns = 4,
    int rows = 128,
    int reservedRows = 0,
  }) {
    final item = replacement.copy(
      x: replacement.x.clamp(0, (columns - replacement.w).clamp(0, columns)),
    );
    if (item.y < reservedRows ||
        !GridGeometry.valid([item], columns: columns, rows: rows)) {
      return null;
    }
    final others = layout.items.where((other) => other.id != item.id).toList();
    final result = <GridItem>[item];
    final displaced = <GridItem>[];
    for (final other in others) {
      if (!GridGeometry.fits(other, result, columns: columns, rows: rows)) {
        displaced.add(other);
        continue;
      }
      result.add(other);
    }
    for (final other in displaced) {
      final placed = GridGeometry.place(
        other,
        result,
        columns: columns,
        rows: rows,
        startRow: reservedRows,
      );
      if (placed == null) {
        return null;
      }
      result.add(placed);
    }
    final byId = {for (final control in result) control.id: control};
    return GridLayout(layout.items.map((old) => byId[old.id]!));
  }
}
