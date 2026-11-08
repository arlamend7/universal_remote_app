import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';
import 'package:universal_remote_app/presentation/views/remote/viewmodels/remote_viewmodel.dart';
import 'package:universal_remote_app/shared/themes/app_themes.dart';

import '../support/fake_provider.dart';
import '../support/memory_storage.dart';
import '../support/test_device.dart';
import '../support/capture_design.dart';

void main() {
  setUpAll(loadDesignFont);
  testWidgets(
    'every catalog widget renders at its minimum footprint without edit frames',
    (tester) async {
      final app = await AppBootstrap.initialize(storage: MemoryStorage());
      app.connection.selected.value = tv;
      final model = GridRemoteViewModel(RemoteViewModel(app));
      for (final definition in RemoteItemRegistry.definitions) {
        final item = GridItem(
          id: 'test',
          definitionId: definition.id,
          x: 0,
          y: 0,
          w: definition.width,
          h: definition.height,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemes.dark,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: item.w * 64 + (item.w - 1) * 8,
                  height: item.h * 80 + (item.h - 1) * 8,
                  child: ElementRenderer(item: item, model: model),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: definition.name);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await app.dispose();
    },
  );
  testWidgets(
    'saved grid removes edit chrome and keeps independent volume/app controls functional',
    (tester) async {
      final provider = FakeProvider(enabledControls: true);
      final app = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: ProviderRegistry()..register(provider),
      );
      await app.savedDevices.save(tv);
      await app.grids.save(
        tv,
        GridLayout([
          GridItem(
            id: 'rocker',
            definitionId: 'volumeDisplayRocker',
            x: 0,
            y: 0,
            w: 1,
            h: 3,
          ),
          GridItem(
            id: 'launch',
            definitionId: 'appShortcut',
            x: 1,
            y: 0,
            w: 1,
            h: 1,
            config: {'targets': '[{"id":"test.youtube","name":"YouTube"}]'},
          ),
          GridItem(
            id: 'group',
            definitionId: 'group',
            x: 0,
            y: 3,
            w: 4,
            h: 3,
            children: [
              GridItem(
                id: 'mute',
                definitionId: 'muteOn',
                x: 0,
                y: 0,
                w: 1,
                h: 1,
              ),
            ],
          ),
        ]),
      );
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: UniversalRemoteApp(dependencies: app),
        ),
      );
      await tester.tap(find.text('Living room'));
      await tester.pumpAndSettle();
      expect(find.text('Save grid'), findsNothing);
      expect(find.text('Configure'), findsNothing);
      await tester.tap(find.byTooltip('Louder'));
      await tester.pumpAndSettle();
      expect(provider.last!.volumeControl.level, 21);
      expect(
        tester.widgetList<TvAppIcon>(find.byType(TvAppIcon)),
        contains(
          isA<TvAppIcon>().having(
            (icon) => icon.appId,
            'appId',
            'test.youtube',
          ),
        ),
      );
      await tester.tap(find.text('YouTube'));
      await tester.pumpAndSettle();
      expect(provider.last!.appControl.launched, 'test.youtube');
      await captureDesign(tester, key, '12-grid-runtime');
      await tester.tap(find.byTooltip('Remote options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customize remote'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is GridEditTile && widget.item.id == 'launch',
        ),
      );
      await tester.pumpAndSettle();
      final choose = find.text('Choose apps');
      await tester.ensureVisible(choose);
      await tester.tap(choose);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Music'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Done').last);
      await tester.tap(find.text('Done').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Music'));
      await tester.pumpAndSettle();
      expect(provider.last!.appControl.launched, 'test.music');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'group drafts apply inside the parent only and save as a borderless controller',
    (tester) async {
      final app = await AppBootstrap.initialize(storage: MemoryStorage());
      await app.savedDevices.save(_catalogTv);
      await app.grids.save(tv, GridLayout([]));
      await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
      await tester.tap(find.text('Devices'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Living room options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customize remote'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-control')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Custom group');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(Card, 'Custom group'));
      await tester.pumpAndSettle();
      expect(find.text('Edit group'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('add-control')).last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Volume rocker');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(Card, 'Volume rocker'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Apply group'));
      await tester.pumpAndSettle();
      expect(app.grids.forDevice(tv)!.items, isEmpty);
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      final saved = app.grids.forDevice(tv)!;
      expect(saved.items.single.children.single.definitionId, 'volumeRocker');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'catalog supports multiple instances and cancel leaves the current layout intact',
    (tester) async {
      final app = await AppBootstrap.initialize(storage: MemoryStorage());
      await app.savedDevices.save(_catalogTv);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: UniversalRemoteApp(dependencies: app),
        ),
      );
      await tester.tap(find.text('Devices'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Living room options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customize remote'));
      await tester.pumpAndSettle();
      await captureDesign(tester, key, '10-grid-editor');
      await tester.tap(find.byKey(const ValueKey('add-control')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'volume rocker');
      await tester.pumpAndSettle();
      await captureDesign(tester, key, '11-widget-library');
      final cards = find.byType(CatalogPreviewCard);
      expect(cards, findsWidgets);
      expect(tester.getSize(cards.first), tester.getSize(cards.at(1)));
      expect(
        tester.getTopLeft(cards.first).dy,
        tester.getTopLeft(cards.at(1)).dy,
      );
      await tester.enterText(find.byType(TextField), 'RESIZE, wide');
      await tester.pumpAndSettle();
      expect(cards, findsOneWidget);
      await tester.tap(find.widgetWithText(Card, 'Volume rocker'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-control')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'volume rocker');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(Card, 'Volume rocker'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back to remote'));
      await tester.pumpAndSettle();
      expect(app.grids.forDevice(tv), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}

final _catalogTv = copyDevice(
  tv,
  capabilities: {RemoteCapability.volume},
  metadata: {'lastConnectedAt': '2026-01-01T00:00:00Z'},
);
