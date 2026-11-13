import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';
import 'package:remote_ui/remote_ui.dart';

import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  testWidgets(
    'drag across pages commits only on drop and leaves occupied slots in place',
    (tester) async {
      tester.view.physicalSize = const Size(640, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final app = await AppBootstrap.initialize(storage: MemoryStorage());
      await app.savedDevices.save(tv);
      await app.grids.save(
        tv,
        GridLayout(
          [
            GridItem(
              id: 'moving',
              definitionId: 'mute',
              x: 0,
              y: 0,
              w: 1,
              h: 1,
            ),
            GridItem(
              id: 'fixed',
              definitionId: 'power',
              x: 1,
              y: 0,
              w: 1,
              h: 1,
            ),
          ],
          columns: 8,
          configuredRows: 20,
          pageStarts: [0, 4],
        ),
      );
      await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
      await tester.tap(find.byTooltip('Living room info'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customize remote'));
      await tester.pumpAndSettle();
      final model = tester
          .state<GridEditorPageState>(find.byType(GridEditorPage))
          .model;
      final editPage = find.byTooltip('Add page');
      final editCanvas = find.byType(GridEditorCanvas);
      expect(
        tester.getCenter(editPage).dy,
        greaterThan(tester.getTopLeft(editCanvas).dy),
      );
      await tester.dragFrom(
        tester.getTopLeft(editCanvas) + const Offset(290, 200),
        const Offset(-250, 0),
      );
      await tester.pumpAndSettle();
      expect(model.pageStart, 0);
      await tester.tap(find.byTooltip('Page 2 of 2'));
      await tester.pumpAndSettle();
      expect(model.pageStart, 4);
      await tester.tap(find.text('View Mode'));
      await tester.pumpAndSettle();
      expect(editPage, findsNothing);
      final dots = find.byTooltip('Page 2 of 2');
      final preview = find.byType(GridRemoteCanvas);
      expect(
        tester.getCenter(dots).dy,
        greaterThan(tester.getTopLeft(preview).dy),
      );
      await tester.dragFrom(tester.getCenter(preview), const Offset(350, 0));
      await tester.pumpAndSettle();
      expect(model.pageStart, 0);
      await tester.tap(find.text('Edit Layout'));
      await tester.pumpAndSettle();
      final tile = find.byWidgetPredicate(
        (widget) => widget is GridEditTile && widget.item.id == 'moving',
      );
      final start = tester.getCenter(tile);
      final vertical = find.descendant(
        of: find.byType(GridEditorPage),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      final scroll = tester.state<ScrollableState>(vertical).position;
      final viewport = tester.getRect(vertical);
      final drag = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 600));
      await drag.moveTo(Offset(start.dx + 70, viewport.bottom - 8));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final down = scroll.pixels;
      await tester.pump(const Duration(milliseconds: 16));
      expect(scroll.pixels, greaterThan(down));
      await drag.moveTo(Offset(start.dx + 70, viewport.top + 8));
      await tester.pump(const Duration(milliseconds: 16));
      final up = scroll.pixels;
      await tester.pump(const Duration(milliseconds: 16));
      expect(scroll.pixels, lessThan(up));
      await drag.cancel();
      await tester.pumpAndSettle();
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      final blocked = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 600));
      await blocked.moveBy(const Offset(37.4, 0));
      await tester.pump();
      await blocked.moveBy(const Offset(37.4, 0));
      await tester.pump();
      await blocked.up();
      await tester.pumpAndSettle();
      expect(model.draft.items.first.x, 0);
      expect(model.draft.items.last.x, 1);
      expect(model.error, isNull);

      final valid = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 600));
      await valid.moveBy(const Offset(37.4, 0));
      await tester.pump();
      await valid.moveBy(const Offset(411.4, 0));
      await tester.pump();
      expect(model.draft.items.first.x, 0);
      await valid.up();
      await tester.pumpAndSettle();
      expect(model.draft.items.first.x, 6);
      expect(model.pageStart, 4);
      expect(model.draft.pageStarts, [0, 4]);
      expect(model.error, isNull);
      expect(model.canUndo, isTrue);
      expect(app.grids.forDevice(tv)!.items.first.x, 0);
      await tester.tap(find.byTooltip('Delete page'));
      await tester.pumpAndSettle();
      expect(find.text('Delete page 2?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete page'));
      await tester.pumpAndSettle();
      expect(model.draft.pageStarts, [0]);
      expect(model.draft.items.single.id, 'fixed');
      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();
      expect(model.draft.pageStarts, [0, 4]);
      expect(model.draft.items.first.x, 6);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('resize snaps the outline and identifies the occupied cell', (
    tester,
  ) async {
    final app = await AppBootstrap.initialize(storage: MemoryStorage());
    await app.savedDevices.save(tv);
    await app.grids.save(
      tv,
      GridLayout([
        GridItem(
          id: 'nav',
          definitionId: 'navigationStrip',
          x: 2,
          y: 0,
          w: 2,
          h: 1,
        ),
        GridItem(id: 'mute', definitionId: 'mute', x: 3, y: 1, w: 1, h: 1),
      ]),
    );
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await tester.tap(find.byTooltip('Living room info'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customize remote'));
    await tester.pumpAndSettle();
    final model = tester
        .state<GridEditorPageState>(find.byType(GridEditorPage))
        .model;
    final resize = find.byTooltip('Resize Home and Back');
    await tester.drag(resize, const Offset(0, 75));
    await tester.pumpAndSettle();
    expect(find.text('A 2 × 2 control would overlap Mute.'), findsOneWidget);
    expect(model.draft.items.first.h, 1);
    await tester.drag(resize, const Offset(-75, 0));
    await tester.pumpAndSettle();
    final item = model.draft.items.first;
    expect(
      (item.x, item.y, item.w, item.h),
      (2, 0, 2, 1),
      reason: 'Home and Back cannot shrink below its 2 × 1 minimum.',
    );
    expect(model.draft.items.last.x, 3);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
