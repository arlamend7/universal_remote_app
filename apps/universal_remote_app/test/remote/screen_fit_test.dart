import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/app/universal_remote_app.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:universal_remote_app/presentation/views/remote/viewports/remote_viewport.dart';
import 'package:universal_remote_app/presentation/views/remote/widgets/remote_header.dart';

import '../support/capture_design.dart';
import '../support/fake_provider.dart';
import '../support/memory_storage.dart';
import '../support/test_device.dart';

GridLayout phoneLayout() => GridLayout([
  GridItem(
    id: 'content',
    definitionId: 'currentActivity',
    x: 0,
    y: 0,
    w: 4,
    h: 1,
  ),
  GridItem(id: 'pad', definitionId: 'directionPad', x: 0, y: 1, w: 2, h: 3),
  GridItem(
    id: 'volume',
    definitionId: 'volumeDisplayRocker',
    x: 2,
    y: 1,
    w: 1,
    h: 3,
  ),
  GridItem(
    id: 'channel',
    definitionId: 'channelDisplayRocker',
    x: 3,
    y: 1,
    w: 1,
    h: 3,
  ),
  GridItem(id: 'apps', definitionId: 'appStrip', x: 0, y: 4, w: 4, h: 1),
  GridItem(
    id: 'channel-name',
    definitionId: 'channelDisplay',
    x: 0,
    y: 5,
    w: 2,
    h: 1,
  ),
  GridItem(id: 'mute', definitionId: 'mute', x: 2, y: 5, w: 1, h: 1),
  GridItem(id: 'status', definitionId: 'connection', x: 3, y: 5, w: 1, h: 1),
]);

void main() {
  setUpAll(loadDesignFont);
  for (final configuration in [
    (const Size(320, 640), 1.0),
    (const Size(390, 844), 1.0),
    (const Size(430, 932), 1.6),
    (const Size(844, 390), 1.0),
    (const Size(320, 640), 1.6),
  ]) {
    testWidgets(
      'starter and customized grid controls fit ${configuration.$1} at text scale ${configuration.$2} without page scrolling',
      (tester) async {
        tester.view.physicalSize = configuration.$1;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = configuration.$2;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        final provider = FakeProvider(enabledControls: true);
        final app = await AppBootstrap.initialize(
          storage: MemoryStorage(),
          registry: ProviderRegistry()..register(provider),
        );
        await app.savedDevices.save(tv);
        final capture = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: capture,
            child: UniversalRemoteApp(dependencies: app),
          ),
        );
        await tester.tap(find.text('Living room'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.descendant(
            of: find.byType(RemoteViewport),
            matching: find.byType(Scrollable),
          ),
          findsNothing,
        );
        final starterBounds = tester.getRect(find.byType(RemoteViewport));
        final slider = tester.getRect(find.byType(Slider));
        expect(slider.bottom, lessThanOrEqualTo(starterBounds.bottom));
        expect(
          tester.getRect(find.text('Inputs')).bottom,
          lessThanOrEqualTo(starterBounds.bottom),
        );
        if (configuration == (const Size(390, 844), 1.0)) {
          await captureDesign(tester, capture, '39-phone-starter');
        }
        await app.grids.save(tv, phoneLayout());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final bounds = tester.getRect(find.byType(RemoteViewport));
        expect(
          find.ancestor(
            of: find.byType(GridRemoteCanvas),
            matching: find.byType(Scrollable),
          ),
          findsNothing,
        );
        for (final item in phoneLayout().items) {
          final control = find.byWidgetPredicate(
            (widget) => widget is GridRemoteItem && widget.item.id == item.id,
          );
          final rect = tester.getRect(control);
          expect(rect.top, greaterThanOrEqualTo(bounds.top));
          expect(rect.left, greaterThanOrEqualTo(bounds.left));
          expect(rect.right, lessThanOrEqualTo(bounds.right + .1));
          expect(rect.bottom, lessThanOrEqualTo(bounds.bottom + .1));
        }
        final header = tester.getRect(find.byType(RemoteHeader));
        final first = tester.getRect(
          find.byWidgetPredicate(
            (widget) => widget is GridRemoteItem && widget.item.id == 'content',
          ),
        );
        // Column spacing (8) + 1px divider + spacing (8).
        expect(first.top - header.bottom, closeTo(17, 1));
        await tester.tap(find.byTooltip('Louder'));
        await tester.pumpAndSettle();
        expect(provider.last!.volumeControl.level, 21);
        if (configuration == (const Size(390, 844), 1.0)) {
          await captureDesign(tester, capture, '40-phone-grid');
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pumpAndSettle();
      },
    );
  }
  testWidgets(
    'View mode fills information with sample data without scrolling, sending commands or saving it',
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
        registry: ProviderRegistry()..register(provider),
      );
      await app.savedDevices.save(tv);
      await app.grids.save(tv, phoneLayout());
      final original = app.grids.forDevice(tv)!.encode();
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
      await tester.tap(find.byTooltip('View'));
      await tester.pumpAndSettle();
      expect(find.text('Sample data · preview only'), findsOneWidget);
      expect(find.text('35'), findsOneWidget);
      expect(find.text('Live TV'), findsOneWidget);
      expect(find.text('National Geographic HD'), findsOneWidget);
      expect(find.text('42'), findsNWidgets(2));
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(GridRemoteCanvas),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
      await captureDesign(tester, capture, '41-sample-phone-preview');
      final preview = tester
          .widget<GridRemoteCanvas>(find.byType(GridRemoteCanvas))
          .remote;
      expect(preview.connection.supports(RemoteCapability.volume), isFalse);
      await GridRemoteViewModel(preview).volumeUp();
      await preview.connection.execute(
        () => app.connection.tvWith(RemoteCapability.volume)!.volumeUp(),
      );
      await tester.tapAt(tester.getCenter(find.byTooltip('Louder')));
      await tester.pumpAndSettle();
      expect(provider.last!.volumeControl.level, 20);
      expect(app.connection.currentContent.value!.appName, 'YouTube');
      expect(app.grids.forDevice(tv)!.encode(), original);
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      expect(app.grids.forDevice(tv)!.encode(), original);
      expect(
        app.savedDevices.devices.value.single.metadata.toString(),
        isNot(contains('National Geographic')),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
    },
  );
  testWidgets('fitted grid keeps accessible controls stable through shutdown', (
    tester,
  ) async {
    final provider = FakeProvider(enabledControls: true);
    final app = await AppBootstrap.initialize(
      storage: MemoryStorage(),
      registry: ProviderRegistry()..register(provider),
    );
    await app.savedDevices.save(tv);
    await app.grids.save(tv, phoneLayout());
    await tester.pumpWidget(UniversalRemoteApp(dependencies: app));
    await tester.tap(find.text('Living room'));
    await tester.pumpAndSettle();
    final controller = provider.last!;
    await tester.tap(find.byTooltip('Power off'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Power off'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(controller.powerControl.shutdowns, 1);
    expect(app.connection.state.value, DeviceConnectionState.disconnected);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
