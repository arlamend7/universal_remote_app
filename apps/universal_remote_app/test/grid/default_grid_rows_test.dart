import 'package:flutter_test/flutter_test.dart';
import 'package:remote_ui/remote_ui.dart';

void main() {
  const gap = SquareGridMetrics.gap;

  test('four square columns fill the width and rows come from the height', () {
    const viewport = SquareGridMetrics(width: 390, height: 640);
    final size = fittedGridSize(viewport);
    expect(size.columns, 4);
    expect(size.cellSize, (390 - 3 * gap) / 4);
    expect(SquareGridMetrics.extent(4, size.cellSize), moreOrLessEquals(390));
    final used = SquareGridMetrics.extent(size.rows, size.cellSize);
    expect(used, lessThanOrEqualTo(640));
    expect(
      used + gap + size.cellSize,
      greaterThan(640),
      reason: 'No room for another whole row.',
    );
  });

  test('taller screens get more rows; short ones still fit the starter', () {
    final tall = fittedGridSize(
      const SquareGridMetrics(width: 390, height: 900),
    );
    final short = fittedGridSize(
      const SquareGridMetrics(width: 390, height: 200),
    );
    expect(
      tall.rows,
      greaterThan(
        fittedGridSize(const SquareGridMetrics(width: 390, height: 640)).rows,
      ),
    );
    expect(short.rows, starterRows);
  });

  test('the starter grid uses the fitted size', () {
    const viewport = SquareGridMetrics(width: 390, height: 700);
    final grid = defaultRemoteGrid(viewport: viewport);
    final size = fittedGridSize(viewport);
    expect(
      (grid.columns, grid.rows, grid.cellSize),
      (4, size.rows, size.cellSize),
    );
    expect(grid.hasValidCanvas, isTrue);
    expect(GridGeometry.valid(grid.items, columns: 4, rows: grid.rows), isTrue);
  });

  test('a saved dashboard keeps its rows on any screen', () async {
    final saved = GridLayout([], configuredRows: 9);
    final restored = GridLayout.decode(saved.encode());
    expect(restored.rows, 9);
  });
}
