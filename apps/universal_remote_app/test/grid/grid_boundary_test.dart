import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';

import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  test(
    'moves past the page edge are rejected without growing the grid',
    () async {
      final app = await AppBootstrap.initialize(storage: MemoryStorage());
      final editor = GridEditorViewModel(
        app.grids,
        tv,
        initial: GridLayout([
          GridItem(
            id: 'strip',
            definitionId: 'navigationStrip',
            x: 0,
            y: 0,
            w: 2,
            h: 1,
          ),
        ], configuredRows: 6),
      );
      final before = editor.draft.encode();
      final strip = editor.draft.items.single;
      expect(editor.move(strip.copy(x: 3)), isFalse);
      expect(editor.move(strip.copy(y: 6)), isFalse);
      expect(editor.draft.encode(), before);
      expect((editor.draft.canvasColumns, editor.draft.rows), (4, 6));
      expect(editor.move(strip.copy(x: 2, y: 5)), isTrue);
    },
  );

  test('resizing past the page edge is rejected', () async {
    final app = await AppBootstrap.initialize(storage: MemoryStorage());
    final editor = GridEditorViewModel(
      app.grids,
      tv,
      initial: GridLayout([
        GridItem(id: 'mute', definitionId: 'mute', x: 3, y: 5, w: 1, h: 1),
      ], configuredRows: 6),
    );
    final mute = editor.draft.items.single;
    expect(editor.roomFor(mute), (width: 1, height: 1));
    editor.resize(mute, 2, 2);
    expect((editor.draft.items.single.w, editor.draft.items.single.h), (1, 1));
    expect((editor.draft.canvasColumns, editor.draft.rows), (4, 6));
  });

  testWidgets('dragging past the edge clamps or rejects, never grows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = await AppBootstrap.initialize(storage: MemoryStorage());
    await app.savedDevices.save(tv);
    await app.grids.save(
      tv,
      GridLayout([
        GridItem(
          id: 'strip',
          definitionId: 'navigationStrip',
          x: 0,
          y: 0,
          w: 2,
          h: 1,
        ),
      ], configuredRows: 6),
    );
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await tester.tap(find.byTooltip('Living room info'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customize remote'));
    await tester.pumpAndSettle();
    final model = tester
        .state<GridEditorPageState>(find.byType(GridEditorPage))
        .model;
    final canvas = find.byType(GridEditorCanvas);
    final width = tester.getSize(canvas).width;
    final tile = find.byType(GridEditTile);

    Future<void> dragBy(double distance) async {
      final drag = await tester.startGesture(tester.getCenter(tile));
      await tester.pump(const Duration(milliseconds: 600));
      for (var step = 1; step <= 5; step++) {
        await drag.moveBy(Offset(distance / 5, 0));
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.getSize(canvas).width, width);
      }
      await drag.up();
      await tester.pumpAndSettle();
    }

    // The footprint would hang past the last column: it is clamped inside.
    await dragBy(190);
    expect((model.draft.items.single.x, model.draft.items.single.w), (2, 2));
    // Released outside the grid: nothing moves and nothing grows.
    final before = model.draft.encode();
    await dragBy(-60);
    await dragBy(400);
    expect(model.draft.items.single.x, isNot(greaterThan(2)));
    expect(model.draft.canvasColumns, 4);
    expect(model.draft.rows, 6);
    expect(tester.getSize(canvas).width, width);
    expect(model.draft.encode().length, before.length);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
