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
    'Home and Back dimensions validate on Done and keep space between buttons',
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
            id: 'navigation',
            definitionId: 'navigationStrip',
            x: 0,
            y: 0,
            w: 2,
            h: 1,
          ),
        ]),
      );
      await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
      await tester.tap(find.byTooltip('Living room info'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customize remote'));
      await tester.pumpAndSettle();
      final tile = find.byType(GridEditTile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      final done = find.text('Done').last;
      await tester.tap(find.byTooltip('Decrease Width'));
      await tester.pumpAndSettle();
      expect(find.textContaining('does not support'), findsNothing);
      await tester.tap(done);
      await tester.pumpAndSettle();
      expect(find.textContaining('does not support 1 × 1'), findsOneWidget);
      await tester.tap(find.byTooltip('Increase Height'));
      await tester.pumpAndSettle();
      await tester.tap(done);
      await tester.pumpAndSettle();
      final model = tester
          .state<GridEditorPageState>(find.byType(GridEditorPage))
          .model;
      expect((model.draft.items.single.w, model.draft.items.single.h), (1, 2));
      final buttons = find.descendant(
        of: tile,
        matching: find.byType(ActionButton),
      );
      expect(buttons, findsNWidgets(2));
      expect(
        tester.getRect(buttons.last).top - tester.getRect(buttons.first).bottom,
        8,
      );
      await tester.tapAt(tester.getTopLeft(tile) + const Offset(30, 60));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Decrease Height'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Increase Width'));
      await tester.pumpAndSettle();
      await tester.tap(done);
      await tester.pumpAndSettle();
      expect((model.draft.items.single.w, model.draft.items.single.h), (2, 1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'grid settings resize the draft, support undo, and keep occupied columns',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final app = await AppBootstrap.initialize(storage: MemoryStorage());
      await app.savedDevices.save(tv);
      await app.grids.save(tv, GridLayout([]));
      await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
      await tester.tap(find.byTooltip('Living room info'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customize remote'));
      await tester.pumpAndSettle();
      final model = tester
          .state<GridEditorPageState>(find.byType(GridEditorPage))
          .model;
      final settings = find.byTooltip('Grid Settings');
      await tester.tap(settings);
      await tester.pumpAndSettle();
      expect(find.text('4 × 8'), findsOneWidget);
      await tester.tap(find.byTooltip('Increase Width'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply Grid'));
      await tester.pumpAndSettle();
      expect(model.draft.columns, 5);
      expect(model.draft.configuredRows, isNotNull);
      expect(app.grids.forDevice(tv)!.columns, 4);
      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();
      expect(model.draft.columns, 4);
      await tester.tap(find.byTooltip('Redo'));
      await tester.pumpAndSettle();
      expect(model.draft.columns, 5);
      expect(model.add('mute', at: (x: 4, y: model.draft.rows - 1)), isNotNull);
      await tester.pumpAndSettle();
      final cell = tester.getSize(find.byType(GridEditTile));
      expect(cell.width, closeTo(66.8, .001));
      expect(cell.height, closeTo(cell.width, .001));
      await tester.tap(settings);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton && widget.tooltip == 'Decrease Width',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton && widget.tooltip == 'Decrease Height',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      expect(app.grids.forDevice(tv)!.columns, 5);
      expect(app.grids.forDevice(tv)!.items.single.x, 4);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('grid settings apply and save independently on page two', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = await AppBootstrap.initialize(storage: MemoryStorage());
    await app.savedDevices.save(tv);
    await app.grids.save(tv, GridLayout([]));
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await tester.tap(find.byTooltip('Living room info'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customize remote'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add page'));
    await tester.pumpAndSettle();

    final model = tester
        .state<GridEditorPageState>(find.byType(GridEditorPage))
        .model;
    await tester.tap(find.byTooltip('Grid Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Page 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Increase Width'));
    await tester.pumpAndSettle();
    expect(
      find.text('Swipe sideways to see all columns on this screen.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Increase Height'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply Grid'));
    await tester.pumpAndSettle();

    expect(model.pageStart, 4);
    expect(model.draft.pageColumns(0), 4);
    expect(model.draft.pageRows(0), 8);
    expect(model.draft.pageColumns(1), 5);
    final pageTwoRows = model.draft.pageRows(1);
    await tester.tap(find.byTooltip('Done'));
    await tester.pumpAndSettle();
    final saved = app.grids.forDevice(tv)!;
    expect(saved.pageColumns(0), 4);
    expect(saved.pageColumns(1), 5);
    expect(saved.pageRows(1), pageTwoRows);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'full page previews edit safely, size choices preserve neighbors, and corner resizing supports undo before save',
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
            y: 5,
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
      await tester.tap(find.byTooltip('Customize remote'));
      await tester.pumpAndSettle();
      expect(find.byType(GridEditorPage), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNothing);
      await captureDesign(tester, capture, '30-simple-editor');
      final volume = find.byWidgetPredicate(
        (widget) => widget is GridEditTile && widget.item.id == 'volume',
      );
      await tester.tap(volume);
      await tester.pumpAndSettle();
      expect(find.text('Edit Control'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'X'), findsNothing);
      expect(find.text('Item Configuration'), findsOneWidget);
      expect(find.text('Larger icons'), findsNothing);
      expect(find.text('Spacing'), findsNothing);
      expect(find.text('Width (blocks)'), findsNothing);
      expect(find.text('Name (optional)'), findsNothing);
      expect(provider.last!.volumeControl.level, 20);
      await tester.tap(find.byTooltip('Increase Width'));
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
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('Reset layout?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(model.draft.items.first.w, 2);
      await tester.tap(find.byTooltip('Add control at column 4, row 1'));
      await tester.pumpAndSettle();
      expect(find.text('Add a control'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Mute');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(Card, 'Mute').first);
      await tester.pumpAndSettle();
      final added = model.draft.items.last;
      expect((added.x, added.y), (3, 0));
      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();
      expect(model.draft.items, hasLength(2));
      final beforeToggle = model.draft.encode();
      await tester.tap(find.text('View Mode'));
      await tester.pumpAndSettle();
      expect(find.byType(GridEditorCanvas), findsNothing);
      expect(find.byType(GridRemoteCanvas), findsOneWidget);
      expect(find.byType(GridEditTile), findsNothing);
      expect(model.draft.encode(), beforeToggle);
      expect(provider.last!.volumeControl.level, 20);
      await captureDesign(tester, capture, '32-view-draft');
      await tester.tap(find.text('Edit Layout'));
      await tester.pumpAndSettle();
      expect(find.byType(GridEditorCanvas), findsOneWidget);
      expect(model.draft.encode(), beforeToggle);
      final handle = find.byTooltip('Resize Volume rocker');
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(49.6, 0));
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
      final rotateLeft = find.byTooltip('Rotate left 90°');
      final rotateRight = find.byTooltip('Rotate right 90°');
      await tester.ensureVisible(rotateLeft);
      await tester.tap(rotateLeft);
      await tester.pumpAndSettle();
      expect(find.text('270°'), findsOneWidget);
      await tester.tap(rotateRight);
      await tester.pumpAndSettle();
      expect(find.text('0°'), findsOneWidget);
      await tester.tap(rotateRight);
      await tester.pumpAndSettle();
      expect(find.text('90°'), findsOneWidget);
      final style = find.byKey(const ValueKey('control-variants'));
      await tester.tap(style);
      await tester.pumpAndSettle();
      expect(find.text('Choose a style'), findsOneWidget);
      expect(
        tester
            .widgetList<CatalogPreviewCard>(find.byType(CatalogPreviewCard))
            .map((card) => card.definition.category),
        everyElement(RemoteItemRegistry.resolve('volumeRocker').category),
      );
      final alternative = find.widgetWithText(CatalogPreviewCard, 'Volume up');
      await tester.scrollUntilVisible(
        alternative,
        140,
        scrollable: find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(alternative);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: style, matching: find.text('Volume up')),
        findsOneWidget,
      );
      expect(model.draft.items.first.definitionId, 'volumeRocker');

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
      expect(app.grids.forDevice(tv)!.items.first.definitionId, 'volumeUp');
      expect(provider.last!.volumeControl.level, 20);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'control preview keeps the reading while editing and resetting its label',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final app = await AppBootstrap.initialize(storage: MemoryStorage());
      await app.savedDevices.save(tv);
      await app.grids.save(
        tv,
        GridLayout([
          GridItem(
            id: 'level',
            definitionId: 'volumeDisplayRocker',
            x: 0,
            y: 0,
            w: 1,
            h: 3,
            config: {'other': 'retained'},
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
      await tester.tap(find.byTooltip('Living room info'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customize remote'));
      await tester.pumpAndSettle();
      await tester.tapAt(
        tester.getTopLeft(find.byType(GridEditTile)) + const Offset(24, 32),
      );
      await tester.pumpAndSettle();
      final model = tester
          .state<GridEditorPageState>(find.byType(GridEditorPage))
          .model;
      await tester.tap(find.text('Item Configuration'));
      await tester.pumpAndSettle();
      expect(find.text('Duplicate'), findsNothing);
      expect(find.text('Remove'), findsNothing);
      final panel = find.widgetWithText(ExpansionTile, 'VOL');
      await tester.tap(panel);
      await tester.pumpAndSettle();
      expect(find.text('Display'), findsOneWidget);
      final indicator = find.widgetWithText(SwitchListTile, 'Show indicator');
      await tester.ensureVisible(indicator);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(indicator).value, isFalse);
      await tester.tap(indicator);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(indicator).value, isTrue);
      expect(find.text('35'), findsWidgets);
      await captureDesign(tester, capture, '33-item-configuration');
      final label = find.byType(TextFormField);
      await tester.enterText(label, 'Sound level');
      await tester.pumpAndSettle();
      expect(find.text('Sound level'), findsWidgets);
      expect(find.text('35'), findsWidgets);
      final reset = find.byTooltip('Reset label');
      await tester.ensureVisible(reset);
      await tester.pumpAndSettle();
      await tester.tap(reset);
      await tester.pumpAndSettle();
      expect(find.text('Sound level'), findsNothing);
      await tester.enterText(label, 'Loudness');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(model.draft.items.single.elementStyles, isEmpty);
      expect(model.draft.items.single.config['other'], 'retained');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'mouse drag moves the selected control without moving neighbors',
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
          GridItem(id: 'b', definitionId: 'power', x: 2, y: 0, w: 1, h: 1),
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
      final tile = find.byWidgetPredicate(
        (widget) => widget is GridEditTile && widget.item.id == 'a',
      );
      final distance = tester.getSize(tile).width + 8;
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
