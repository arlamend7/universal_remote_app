import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:remote_ui/remote_ui.dart';

import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  testWidgets(
    'touch drag snaps from the grabbed cell and reorders occupied slots',
    (tester) async {
      final app = await AppBootstrap.initialize(storage: MemoryStorage());
      final model = GridEditorViewModel(
        app.grids,
        tv,
        initial: GridLayout([
          GridItem(
            id: 'moving',
            kind: GridWidgetKind.mute,
            x: 0,
            y: 0,
            w: 1,
            h: 1,
          ),
          GridItem(
            id: 'fixed',
            kind: GridWidgetKind.power,
            x: 1,
            y: 0,
            w: 1,
            h: 1,
          ),
        ]),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 424,
                child: SingleChildScrollView(
                  child: ListenableBuilder(
                    listenable: model,
                    builder: (_, _) => GridEditorCanvas(model: model),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final tile = find.byWidgetPredicate(
        (widget) => widget is GridEditTile && widget.item.id == 'moving',
      );
      final start = tester.getCenter(tile);
      final blocked = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 600));
      await blocked.moveBy(const Offset(108, 0));
      await tester.pump();
      await blocked.up();
      await tester.pumpAndSettle();
      expect(model.draft.items.first.x, 1);
      expect(model.error, isNull);
      model.undo();
      await tester.pumpAndSettle();

      final valid = await tester.startGesture(tester.getCenter(tile));
      await tester.pump(const Duration(milliseconds: 600));
      await valid.moveBy(const Offset(216, 0));
      await tester.pump();
      await valid.up();
      await tester.pumpAndSettle();
      expect(model.draft.items.first.x, 2);
      expect(model.error, isNull);
      expect(model.canUndo, isTrue);
      expect(app.grids.forDevice(tv), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      model.dispose();
      await app.dispose();
    },
  );
}
