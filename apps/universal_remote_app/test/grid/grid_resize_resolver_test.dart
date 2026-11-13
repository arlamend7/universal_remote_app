import 'package:flutter_test/flutter_test.dart';
import 'package:remote_ui/remote_ui.dart';

GridItem control(
  String id,
  String definitionId,
  int x,
  int y,
  int w,
  int h, {
  ItemAxis? position,
}) => GridItem(
  id: id,
  definitionId: definitionId,
  x: x,
  y: y,
  w: w,
  h: h,
  position: position,
);

(int, int, int, int)? footprint(GridItem? item) =>
    item == null ? null : (item.x, item.y, item.w, item.h);

void main() {
  test('example A: growing past the right edge moves left', () {
    final pad = control('pad', 'touchpad', 2, 1, 2, 2);
    final resolved = GridResizeResolver.resolve(
      pad,
      3,
      2,
      const [],
      columns: 4,
      rows: 6,
    );
    expect(footprint(resolved), (1, 1, 3, 2));
  });

  test('example B: growing past the bottom edge moves up', () {
    final pad = control('pad', 'touchpad', 0, 4, 2, 2);
    final resolved = GridResizeResolver.resolve(
      pad,
      2,
      3,
      const [],
      columns: 4,
      rows: 6,
    );
    expect(footprint(resolved), (0, 3, 2, 3));
  });

  test('example C: an occupied neighbour is avoided, never moved', () {
    final pad = control('pad', 'touchpad', 0, 0, 2, 2);
    final mute = control('mute', 'mute', 2, 0, 1, 1);
    final resolved = GridResizeResolver.resolve(
      pad,
      3,
      2,
      [mute],
      columns: 4,
      rows: 6,
    );
    expect(footprint(resolved), (0, 1, 3, 2));
    expect(GridGeometry.overlaps(resolved!, mute), isFalse);
    expect(footprint(mute), (2, 0, 1, 1));
  });

  test('without room for the full size it shrinks only as needed', () {
    final pad = control('pad', 'touchpad', 0, 0, 2, 2);
    final others = [
      control('a', 'mute', 3, 0, 1, 1),
      control('b', 'mute', 3, 1, 1, 1),
    ];
    final resolved = GridResizeResolver.resolve(
      pad,
      4,
      2,
      others,
      columns: 4,
      rows: 2,
    );
    expect(footprint(resolved), (0, 0, 3, 2));
  });

  test('a request below the minimum clamps to the effective minimum', () {
    final vertical = control(
      'rocker',
      'volumeRocker',
      0,
      0,
      1,
      3,
      position: ItemAxis.vertical,
    );
    expect(
      footprint(
        GridResizeResolver.resolve(
          vertical,
          1,
          1,
          const [],
          columns: 4,
          rows: 6,
        ),
      ),
      (0, 0, 1, 2),
    );
    final horizontal = control(
      'rocker',
      'volumeRocker',
      0,
      0,
      3,
      1,
      position: ItemAxis.horizontal,
    );
    final resolved = GridResizeResolver.resolve(
      horizontal,
      1,
      1,
      const [],
      columns: 4,
      rows: 6,
    );
    expect(footprint(resolved), (0, 0, 2, 1));
    expect(resolved!.arrangement, ItemAxis.horizontal);
  });

  test('requests beyond the page never add columns or rows', () {
    final pad = control('pad', 'touchpad', 1, 1, 2, 2);
    final resolved = GridResizeResolver.resolve(
      pad,
      9,
      20,
      const [],
      columns: 4,
      rows: 6,
    );
    expect(footprint(resolved), (0, 0, 4, 6));
  });

  test('resizing never changes Position', () {
    final vertical = control(
      'rocker',
      'volumeRocker',
      0,
      0,
      1,
      2,
      position: ItemAxis.vertical,
    );
    final wide = GridResizeResolver.resolve(
      vertical,
      4,
      2,
      const [],
      columns: 4,
      rows: 6,
    );
    expect((wide!.w, wide.h), (4, 2));
    expect(wide.arrangement, ItemAxis.vertical);
    final horizontal = control(
      'rocker',
      'volumeRocker',
      0,
      0,
      2,
      1,
      position: ItemAxis.horizontal,
    );
    final tall = GridResizeResolver.resolve(
      horizontal,
      2,
      4,
      const [],
      columns: 4,
      rows: 6,
    );
    expect((tall!.w, tall.h), (2, 4));
    expect(tall.arrangement, ItemAxis.horizontal);
  });

  test('reserved rows are never used', () {
    final mute = control('mute', 'mute', 0, 1, 1, 1);
    final resolved = GridResizeResolver.resolve(
      mute,
      1,
      6,
      const [],
      columns: 4,
      rows: 6,
      startRow: 1,
    );
    expect(footprint(resolved), (0, 1, 1, 5));
  });

  test('exact-size placement does not shrink, and gives up without room', () {
    final pad = control('pad', 'touchpad', 0, 0, 2, 2);
    final others = [
      for (var y = 0; y < 2; y++) control('m$y', 'mute', 1, y, 1, 1),
    ];
    expect(
      GridResizeResolver.resolve(
        pad,
        3,
        2,
        others,
        columns: 4,
        rows: 2,
        shrinkToFit: false,
      ),
      isNull,
    );
    expect(
      GridResizeResolver.resolve(pad, 2, 2, others, columns: 4, rows: 2),
      isNotNull,
      reason: 'Columns 2–3 still hold a 2 × 2 pad.',
    );
    final blocked = [
      for (var y = 0; y < 2; y++)
        for (final x in [1, 3]) control('b$x$y', 'mute', x, y, 1, 1),
    ];
    expect(
      GridResizeResolver.resolve(pad, 2, 2, blocked, columns: 4, rows: 2),
      isNull,
    );
  });
}
