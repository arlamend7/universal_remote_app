import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';
import 'package:universal_remote_app/app/app_dependencies.dart';

import '../support/memory_storage.dart';
import '../support/test_device.dart';

/// Drives the real nine-dot handle in the remote editor.
final class _Editor {
  _Editor(this.tester, this.app);
  final WidgetTester tester;
  final AppDependencies app;

  GridEditorViewModel get model =>
      tester.state<GridEditorPageState>(find.byType(GridEditorPage)).model;

  GridItem item(String id) =>
      model.draft.items.firstWhere((item) => item.id == id);

  (int, int, int, int) footprint(String id) {
    final found = item(id);
    return (found.x, found.y, found.w, found.h);
  }

  Finder tile(String id) => find.byWidgetPredicate(
    (widget) => widget is GridEditTile && widget.item.id == id,
  );

  Finder handle(String id) => find.descendant(
    of: tile(id),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Tooltip && (widget.message ?? '').startsWith('Resize '),
    ),
  );

  /// One grid step in pixels, measured from the tile as laid out.
  double stride(String id) {
    final size = tester.getSize(tile(id));
    return (size.width + SquareGridMetrics.gap) / item(id).w;
  }

  Future<TestGesture> grab(String id, {PointerDeviceKind? kind}) async {
    final gesture = await tester.startGesture(
      tester.getCenter(handle(id)),
      kind: kind ?? PointerDeviceKind.touch,
    );
    await tester.pump();
    return gesture;
  }

  /// Drags [id]'s handle by whole cells, in [steps] small moves.
  Future<void> resize(String id, int columns, int rows, {int steps = 4}) async {
    final step = stride(id);
    final gesture = await grab(id);
    final delta = Offset(columns * step, rows * step) / steps.toDouble();
    for (var index = 0; index < steps; index++) {
      await gesture.moveBy(delta);
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }
}

Future<_Editor> openEditor(
  WidgetTester tester,
  List<GridItem>? items, {
  Size size = const Size(390, 844),
  int columns = 4,
  List<int> pageStarts = const [0],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final app = await AppBootstrap.initialize(storage: MemoryStorage());
  await app.savedDevices.save(tv);
  if (items != null) {
    await app.grids.save(
      tv,
      GridLayout(
        items,
        columns: columns,
        configuredRows: 6,
        pageStarts: pageStarts,
      ),
    );
  }
  await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
  await tester.tap(find.byTooltip('Living room info'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Customize remote'));
  await tester.pumpAndSettle();
  return _Editor(tester, app);
}

GridItem mute(String id, int x, int y) =>
    GridItem(id: id, definitionId: 'mute', x: x, y: y, w: 1, h: 1);

GridItem rocker(int x, int y, int w, int h, ItemAxis position) => GridItem(
  id: 'rocker',
  definitionId: 'volumeRocker',
  x: x,
  y: y,
  w: w,
  h: h,
  position: position,
);

Future<void> close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the handle resizes in every direction', (tester) async {
    final editor = await openEditor(tester, [mute('m', 1, 1)]);
    await editor.resize('m', 1, 0);
    expect(editor.footprint('m'), (1, 1, 2, 1), reason: 'right');
    await editor.resize('m', -1, 0);
    expect(editor.footprint('m'), (1, 1, 1, 1), reason: 'left');
    await editor.resize('m', 0, 1);
    expect(editor.footprint('m'), (1, 1, 1, 2), reason: 'down');
    await editor.resize('m', 0, -1);
    expect(editor.footprint('m'), (1, 1, 1, 1), reason: 'up');
    await editor.resize('m', 2, 2);
    expect(editor.footprint('m'), (1, 1, 3, 3), reason: 'diagonal');
    await close(tester);
  });

  testWidgets('dragging past the top or left edge extends that way', (
    tester,
  ) async {
    final editor = await openEditor(tester, [
      mute('up', 1, 3),
      mute('left', 1, 5),
      mute('both', 3, 3),
    ]);
    await editor.resize('up', 0, -1);
    expect(editor.footprint('up'), (1, 2, 1, 2), reason: 'up');
    await editor.resize('left', -1, 0);
    expect(editor.footprint('left'), (0, 5, 2, 1), reason: 'left');
    await editor.resize('both', -1, -1);
    expect(editor.footprint('both'), (2, 2, 2, 2), reason: 'up and left');
    expect(GridGeometry.valid(editor.model.draft.items), isTrue);
    await close(tester);
  });

  testWidgets('your screenshot: Home dragged up into the pad stays valid', (
    tester,
  ) async {
    final editor = await openEditor(tester, null);
    String idOf(String definitionId) => editor.model.draft.items
        .firstWhere((item) => item.definitionId == definitionId)
        .id;
    final strip = idOf('navigationStrip');
    final pad = editor.footprint(idOf('directionPad'));
    expect(editor.footprint(strip), (1, 4, 2, 1));
    // One column, one row up: 1 × 2 over the pad. The pad is in the way, so
    // the vertical 1 × 2 goes to the nearest free place instead.
    await editor.resize(strip, -1, -1);
    expect(editor.footprint(strip), (1, 4, 1, 2));
    expect(editor.item(strip).arrangement, ItemAxis.vertical);
    expect(editor.footprint(idOf('directionPad')), pad);
    expect(GridGeometry.valid(editor.model.draft.items), isTrue);
    // Dragging left into Apps never overlaps it.
    final apps = editor.footprint(idOf('apps'));
    await editor.resize(strip, -2, -1);
    expect(editor.footprint(idOf('apps')), apps);
    expect(GridGeometry.valid(editor.model.draft.items), isTrue);
    await close(tester);
  });

  testWidgets('reaching left from page 2 stays on page 2', (tester) async {
    final editor = await openEditor(
      tester,
      [mute('m', 4, 0)],
      columns: 8,
      pageStarts: const [0, 4],
    );
    await tester.tap(find.byTooltip('Page 2 of 2'));
    await tester.pumpAndSettle();
    await editor.resize('m', -2, 0);
    final grown = editor.item('m');
    expect(grown.x, greaterThanOrEqualTo(4));
    expect(editor.model.draft.staysOnPage(grown), isTrue);
    expect(editor.model.draft.canvasColumns, 8);
    await close(tester);
  });

  testWidgets('a mouse drag on the handle resizes, not moves', (tester) async {
    final editor = await openEditor(tester, [mute('m', 0, 0)]);
    final step = editor.stride('m');
    final gesture = await editor.grab('m', kind: PointerDeviceKind.mouse);
    await gesture.moveBy(Offset(step, step));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(editor.footprint('m'), (0, 0, 2, 2));
    expect(find.text('Edit Control'), findsNothing);
    await close(tester);
  });

  testWidgets('shrinking below the effective minimum clamps to it', (
    tester,
  ) async {
    final editor = await openEditor(tester, [
      rocker(0, 0, 2, 4, ItemAxis.vertical),
    ]);
    // Back to the top-left cell: 1 × 1 asked, clamped to the 1 × 2 minimum.
    await editor.resize('rocker', -1, -3);
    expect(editor.footprint('rocker'), (0, 0, 1, 2));
    expect(editor.item('rocker').arrangement, ItemAxis.vertical);
    await close(tester);
  });

  testWidgets('regression: the starter grid edge item can be resized', (
    tester,
  ) async {
    final editor = await openEditor(tester, null);
    final id = editor.model.draft.items
        .firstWhere((item) => item.definitionId == 'mute')
        .id;
    expect(editor.footprint(id), (3, 0, 1, 1));
    await editor.resize(id, 1, 0);
    final grown = editor.item(id);
    expect((grown.w, grown.h), (2, 1));
    expect(editor.model.error, isNull);
    expect(GridGeometry.valid(editor.model.draft.items), isTrue);
    expect(editor.model.draft.canvasColumns, 4);
    await close(tester);
  });

  testWidgets(
    'your screenshot: Home and Back dragged to 1 × 2 turns vertical',
    (tester) async {
      final editor = await openEditor(tester, null);
      final id = editor.model.draft.items
          .firstWhere((item) => item.definitionId == 'navigationStrip')
          .id;
      expect(editor.footprint(id), (1, 4, 2, 1));
      expect(editor.item(id).arrangement, ItemAxis.horizontal);
      await editor.resize(id, -1, 1);
      expect(editor.footprint(id), (1, 4, 1, 2));
      expect(editor.item(id).arrangement, ItemAxis.vertical);
      expect(GridGeometry.valid(editor.model.draft.items), isTrue);
      // Dragging back to 2 × 1 turns it horizontal again.
      await editor.resize(id, 1, -1);
      expect(editor.footprint(id), (1, 4, 2, 1));
      expect(editor.item(id).arrangement, ItemAxis.horizontal);
      await close(tester);
    },
  );

  testWidgets('shapes valid for the current Position never flip it', (
    tester,
  ) async {
    final editor = await openEditor(tester, [
      rocker(0, 0, 1, 2, ItemAxis.vertical),
    ]);
    await editor.resize('rocker', 3, 0);
    expect(editor.footprint('rocker'), (0, 0, 4, 2));
    expect(editor.item('rocker').arrangement, ItemAxis.vertical);
    await close(tester);
  });

  testWidgets('growing at the bottom edge moves up instead of adding rows', (
    tester,
  ) async {
    final editor = await openEditor(tester, [mute('m', 0, 5)]);
    await editor.resize('m', 0, 1);
    expect(editor.footprint('m'), (0, 4, 1, 2));
    expect(editor.model.draft.rows, 6);
    await close(tester);
  });

  testWidgets(
    'growing at the right edge moves left instead of adding columns',
    (tester) async {
      final editor = await openEditor(tester, [mute('m', 3, 2)]);
      await editor.resize('m', 1, 0);
      expect(editor.footprint('m'), (2, 2, 2, 1));
      expect(editor.model.draft.canvasColumns, 4);
      await close(tester);
    },
  );

  testWidgets('growing into a neighbour never overlaps or moves it', (
    tester,
  ) async {
    final editor = await openEditor(tester, [mute('m', 0, 0), mute('n', 1, 0)]);
    await editor.resize('m', 1, 0);
    final grown = editor.item('m');
    expect((grown.w, grown.h), (2, 1));
    expect(editor.footprint('n'), (1, 0, 1, 1));
    expect(GridGeometry.valid(editor.model.draft.items), isTrue);
    await close(tester);
  });

  testWidgets('the live preview commits nothing until release', (tester) async {
    final editor = await openEditor(tester, [mute('m', 0, 0)]);
    final before = editor.model.draft.encode();
    final canvas = tester.getSize(find.byType(GridEditorCanvas));
    final step = editor.stride('m');
    final gesture = await editor.grab('m');
    for (var index = 0; index < 30; index++) {
      await gesture.moveBy(Offset(step / 10, step / 10));
      await tester.pump(const Duration(milliseconds: 4));
      expect(tester.getSize(find.byType(GridEditorCanvas)), canvas);
      expect(editor.model.draft.encode(), before);
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(editor.footprint('m'), (0, 0, 4, 4));
    expect(tester.getSize(find.byType(GridEditorCanvas)), canvas);
    await close(tester);
  });

  testWidgets('a cancelled gesture restores the original', (tester) async {
    final editor = await openEditor(tester, [mute('m', 0, 0)]);
    final step = editor.stride('m');
    final gesture = await editor.grab('m');
    await gesture.moveBy(Offset(step * 2, step * 2));
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(editor.footprint('m'), (0, 0, 1, 1));
    await close(tester);
  });

  testWidgets('a committed resize is saved with the dashboard', (tester) async {
    final editor = await openEditor(tester, [mute('m', 3, 5)]);
    await editor.resize('m', 1, 1);
    expect(editor.footprint('m'), (2, 4, 2, 2));
    await tester.tap(find.byTooltip('Done'));
    await tester.pumpAndSettle();
    final saved = editor.app.grids.forDevice(tv)!.items.single;
    expect((saved.x, saved.y, saved.w, saved.h), (2, 4, 2, 2));
    await close(tester);
  });

  testWidgets('after a Position change the handle uses the swapped minimum', (
    tester,
  ) async {
    final editor = await openEditor(tester, [
      rocker(0, 0, 1, 2, ItemAxis.vertical),
    ]);
    editor.model.changePosition(editor.item('rocker'), ItemAxis.horizontal);
    await tester.pumpAndSettle();
    expect(editor.footprint('rocker'), (0, 0, 2, 1));
    await editor.resize('rocker', -1, 0);
    expect(editor.footprint('rocker'), (0, 0, 2, 1));
    await editor.resize('rocker', 0, 2);
    expect(editor.footprint('rocker'), (0, 0, 2, 3));
    expect(editor.item('rocker').arrangement, ItemAxis.horizontal);
    await close(tester);
  });

  testWidgets('a resize on page 2 stays on page 2', (tester) async {
    final editor = await openEditor(
      tester,
      [mute('m', 7, 0)],
      columns: 8,
      pageStarts: const [0, 4],
    );
    await tester.tap(find.byTooltip('Page 2 of 2'));
    await tester.pumpAndSettle();
    await editor.resize('m', 1, 0);
    final grown = editor.item('m');
    expect((grown.x, grown.w), (6, 2));
    expect(editor.model.draft.staysOnPage(grown), isTrue);
    expect(editor.model.draft.canvasColumns, 8);
    await close(tester);
  });

  testWidgets('cell conversion follows the screen size', (tester) async {
    final editor = await openEditor(tester, [
      mute('m', 0, 0),
    ], size: const Size(700, 1000));
    await editor.resize('m', 2, 1);
    expect(editor.footprint('m'), (0, 0, 3, 2));
    await close(tester);
  });

  testWidgets('Edit Control shows the resized size and leaves no stale state', (
    tester,
  ) async {
    final editor = await openEditor(tester, [mute('m', 0, 0)]);
    await editor.resize('m', 1, 1);
    await tester.tap(editor.tile('m'));
    await tester.pumpAndSettle();
    expect(editor.model.selected, 'm');
    expect(
      find.descendant(
        of: find.byType(AppSheet),
        matching: find.widgetWithText(TextField, '2'),
      ),
      findsNWidgets(2),
    );
    await tester.ensureVisible(find.text('Done').last);
    await tester.tap(find.text('Done').last);
    await tester.pumpAndSettle();
    expect(editor.model.selected, isNull);
    expect(editor.footprint('m'), (0, 0, 2, 2));
    await editor.resize('m', 1, 0);
    expect(editor.footprint('m'), (0, 0, 3, 2));
    await close(tester);
  });
}
