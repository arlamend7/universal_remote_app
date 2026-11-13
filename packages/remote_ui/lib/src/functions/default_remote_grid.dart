import '../definitions/enums/item_axis.dart';
import '../definitions/remote_item_registry.dart';
import '../layout/models/grid_item.dart';
import '../layout/models/grid_layout.dart';
import '../layout/models/square_grid_metrics.dart';

/// Rows the starter controls occupy. A fitted grid never has fewer, so the
/// starter layout always fits.
const starterRows = 5;

/// Rows used only when no screen size is known yet (for example in tests).
const unmeasuredRows = starterRows + 1;

/// A larger preset offered alongside the screen-fitted grid.
const largeGridSize = (columns: 5, rows: 7);

/// Four square columns that fill [viewport]'s width, and as many whole rows
/// of that size as fit in its height. Never a partial row.
({int columns, int rows, double cellSize}) fittedGridSize(
  SquareGridMetrics viewport,
) {
  const columns = GridLayout.defaultColumns;
  if (!viewport.width.isFinite || !viewport.height.isFinite) {
    return (
      columns: columns,
      rows: unmeasuredRows,
      cellSize: SquareGridMetrics.minimumCell,
    );
  }
  final cell = viewport.cellSize(columns);
  final rows = viewport
      .fittingRows(cell)
      .clamp(starterRows, GridLayout.maxRows);
  return (columns: columns, rows: rows, cellSize: cell);
}

/// The starter remote: 4 columns with the directional pad centered, sized to
/// [viewport] when it is known.
GridLayout defaultRemoteGrid({SquareGridMetrics? viewport}) {
  final size = viewport == null
      ? (
          columns: GridLayout.defaultColumns,
          rows: unmeasuredRows,
          cellSize: SquareGridMetrics.minimumCell,
        )
      : fittedGridSize(viewport);
  return GridLayout(
    [
      _item('currentActivity', 0, 0, 3, 1),
      _item('mute', 3, 0, 1, 1),
      _item('volumeRocker', 0, 1, 1, 3),
      _item('directionPad', 1, 1, 2, 3),
      _item('channelRocker', 3, 1, 1, 3),
      _item('apps', 0, 4, 1, 1),
      _item('navigationStrip', 1, 4, 2, 1),
      _item('inputs', 3, 4, 1, 1),
    ],
    columns: size.columns,
    configuredRows: size.rows,
    cellSize: size.cellSize,
  );
}

GridItem _item(String definitionId, int x, int y, int w, int h) {
  final definition = RemoteItemRegistry.resolve(definitionId);
  final ItemAxis? position = definition.supportsPosition
      ? definition.defaultPosition
      : null;
  return GridItem(
    id: 'default-$definitionId',
    definitionId: definitionId,
    x: x,
    y: y,
    w: w,
    h: h,
    position: position,
  );
}
