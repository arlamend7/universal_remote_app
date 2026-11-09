import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';
import 'package:remote_ui/remote_ui.dart';

import '../support/memory_storage.dart';
import '../support/test_device.dart';
import '../support/fake_provider.dart';
import '../support/capture_design.dart';

void main() {
  setUpAll(loadDesignFont);
  test('every registered control has a valid default size and a valid default size', () {
    for (final definition in RemoteItemRegistry.definitions) {
      expect(
        definition.accepts(definition.width, definition.height),
        isTrue,
        reason: definition.id,
      );
    }
  });
  testWidgets(
    'full page previews edit safely, size choices reflow neighbors, and corner resizing supports undo before save',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final provider = FakeProvider(enabledControls: true);
      final app = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: ProviderRegistry()..registerDefinition(provider.definition),
      );
      await app.savedDevices.save(tv);
      await app.grids.save(
        tv,
        GridLayout([
          GridItem(
            id: 'volume',
            definitionId: 'volumeRocker',
            x: 0,
            y: 0,
            w: 1,
            h: 2,
          ),
          GridItem(
            id: 'app',
            definitionId: 'appShortcut',
            x: 1,
            y: 0,
            w: 1,
            h: 1,
            config: {'targets': '[{"id":"test.youtube","name":"YouTube"}]'},
          ),
        ]),
      );
      final capture = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: UniversalRemoteApp(dependencies: app),
        ),
      );
      await tester.tap(find.text('Living room'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remote options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customize remote'));
      await tester.pumpAndSettle();
      expect(find.byType(GridEditorPage), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNothing);
      await captureDesign(tester, capture, '30-simple-editor');
      final volume = find.byWidgetPredicate(
        (widget) => widget is GridEditTile && widget.item.id == 'volume',
      );
      await tester.tap(volume);
      await tester.pumpAndSettle();
      expect(find.text('Edit control'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'X'), findsNothing);
      await tester.tap(find.text('Style'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a style'), findsOneWidget);
      expect(find.byType(CatalogPreviewCard), findsAtLeastNWidgets(2));
      expect(find.text('Volume rocker'), findsWidgets);
      expect(find.text('Up'), findsNothing);
      await tester.tap(find.byTooltip('Close styles'));
      await tester.pumpAndSettle();
      expect(provider.last!.volumeControl.level, 20);
      await tester.tap(find.text('Half'));
      await tester.pumpAndSettle();
      await captureDesign(tester, capture, '31-simple-control-settings');
      await tester.ensureVisible(find.text('Done').last);
      await tester.tap(find.text('Done').last);
      await tester.pumpAndSettle();
      final model = tester
          .state<GridEditorPageState>(find.byType(GridEditorPage))
          .model;
      expect(model.draft.items.first.w, 2);
      expect(GridGeometry.valid(model.draft.items), isTrue);
      expect(app.grids.forDevice(tv)!.items.first.w, 1);
      final beforeToggle = model.draft.encode();
      await tester.tap(find.byTooltip('View'));
      await tester.pumpAndSettle();
      expect(find.byType(GridEditorCanvas), findsNothing);
      expect(find.byType(GridRemoteCanvas), findsOneWidget);
      expect(find.byType(GridEditTile), findsNothing);
      expect(model.draft.encode(), beforeToggle);
      expect(provider.last!.volumeControl.level, 20);
      await captureDesign(tester, capture, '32-view-draft');
      await tester.tap(find.byTooltip('Edit'));
      await tester.pumpAndSettle();
      expect(find.byType(GridEditorCanvas), findsOneWidget);
      expect(model.draft.encode(), beforeToggle);
      final handle = find.byTooltip('Resize Volume rocker');
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(85, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(model.draft.items.first.w, 4);
      expect(GridGeometry.valid(model.draft.items), isTrue);
      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();
      expect(model.draft.items.first.w, 2);
      await tester.tap(find.byTooltip('Redo'));
      await tester.pumpAndSettle();
      expect(model.draft.items.first.w, 4);
      await tester.ensureVisible(volume);
      await tester.tap(volume);
      await tester.pumpAndSettle();
      final rotate = find.text('Rotate · 0°');
      await tester.ensureVisible(rotate);
      await tester.tap(rotate);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Done').last);
      await tester.tap(find.text('Done').last);
      await tester.pumpAndSettle();
      expect(model.draft.items.first.quarterTurns, 1);
      expect(model.draft.items.first.w, 2);
      expect(GridGeometry.valid(model.draft.items), isTrue);
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(GridEditorPage), findsNothing);
      expect(app.grids.forDevice(tv)!.items.first.quarterTurns, 1);
      expect(provider.last!.volumeControl.level, 20);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'mouse drag works on the real page without holding and moves occupied neighbors',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final app = await AppBootstrap.initialize(storage: MemoryStorage());
      await app.savedDevices.save(tv);
      await app.grids.save(
        tv,
        GridLayout([
          GridItem(id: 'a', definitionId: 'mute', x: 0, y: 0, w: 1, h: 1),
          GridItem(id: 'b', definitionId: 'power', x: 1, y: 0, w: 1, h: 1),
        ]),
      );
      await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
      await tester.tap(find.byTooltip('Living room options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customize remote'));
      await tester.pumpAndSettle();
      final model = tester
          .state<GridEditorPageState>(find.byType(GridEditorPage))
          .model;
      final tile = find.byWidgetPredicate(
        (widget) => widget is GridEditTile && widget.item.id == 'a',
      );
      final distance =
          (tester.getSize(find.byType(GridEditorCanvas)).width + 8) / 4;
      final mouse = await tester.startGesture(
        tester.getCenter(tile),
        kind: PointerDeviceKind.mouse,
      );
      await mouse.moveBy(Offset(distance / 2, 0));
      await tester.pump();
      await mouse.moveBy(Offset(distance / 2, 0));
      await tester.pump();
      await mouse.up();
      await tester.pumpAndSettle();
      expect(model.draft.items.first.x, 1);
      expect(GridGeometry.valid(model.draft.items), isTrue);
      expect(app.grids.forDevice(tv)!.items.first.x, 0);
      final vertical = await tester.startGesture(
        tester.getCenter(tile),
        kind: PointerDeviceKind.mouse,
      );
      await vertical.moveBy(Offset(0, distance / 2));
      await tester.pump();
      await vertical.moveBy(Offset(0, distance / 2));
      await tester.pump();
      await vertical.up();
      await tester.pumpAndSettle();
      expect(model.draft.items.first.y, 1);
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      expect(app.grids.forDevice(tv)!.items.first.x, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
