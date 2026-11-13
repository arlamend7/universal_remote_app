import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';

import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  testWidgets(
    'Edit Control changes Position, size and background independently and '
    'clears the highlight however it closes',
    (tester) async {
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
            id: 'rocker',
            definitionId: 'volumeRocker',
            x: 0,
            y: 0,
            w: 2,
            h: 4,
            position: ItemAxis.vertical,
          ),
          GridItem(
            id: 'dial',
            definitionId: 'volumeDial',
            x: 2,
            y: 0,
            w: 2,
            h: 2,
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
      Finder tile(String id) => find.byWidgetPredicate(
        (widget) => widget is GridEditTile && widget.item.id == id,
      );
      GridItem item(String id) =>
          model.draft.items.firstWhere((item) => item.id == id);
      Future<void> open(String id) async {
        await tester.tap(tile(id));
        await tester.pumpAndSettle();
        expect(model.selected, id);
      }

      Future<void> done() async {
        await tester.ensureVisible(find.text('Done').last);
        await tester.tap(find.text('Done').last);
        await tester.pumpAndSettle();
      }

      // Position rearranges the elements only.
      await open('rocker');
      expect(find.text('Position'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Border'), findsNothing);
      await tester.tap(find.text('Horizontal'));
      await tester.pumpAndSettle();
      await done();
      expect(item('rocker').position, ItemAxis.horizontal);
      expect((item('rocker').w, item('rocker').h), (2, 4));
      expect(model.selected, isNull, reason: 'Done clears the highlight.');

      // Swiping the sheet away discards the draft and the highlight.
      await open('rocker');
      await tester.tap(find.text('Reset to minimum size'));
      await tester.pumpAndSettle();
      await tester.drag(find.text('Edit Control'), const Offset(0, 800));
      await tester.pumpAndSettle();
      expect(find.text('Edit Control'), findsNothing);
      expect(model.selected, isNull, reason: 'Dismissal clears it too.');
      expect((item('rocker').w, item('rocker').h), (2, 4));

      // Back navigation clears it as well.
      await open('rocker');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Edit Control'), findsNothing);
      expect(model.selected, isNull);

      // Reset affects size only; Show Background affects the outer card only.
      await open('rocker');
      await tester.tap(find.text('Reset to minimum size'));
      await tester.pumpAndSettle();
      final background = find.widgetWithText(SwitchListTile, 'Show Background');
      await tester.dragUntilVisible(
        background,
        find.byType(ListView).last,
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      await tester.tap(background);
      await tester.pumpAndSettle();
      await done();
      expect((item('rocker').w, item('rocker').h), (1, 2));
      expect(item('rocker').position, ItemAxis.horizontal);
      expect(item('rocker').style.showBackground, isFalse);

      // Square minimums never offer Position, even when enlarged.
      await open('dial');
      expect(find.text('Position'), findsNothing);
      await tester.tap(find.byTooltip('Increase Height'));
      await tester.pumpAndSettle();
      expect(find.text('Position'), findsNothing);
      await done();
      expect((item('dial').w, item('dial').h), (2, 3));
      expect(item('dial').position, isNull);
      expect(model.selected, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
