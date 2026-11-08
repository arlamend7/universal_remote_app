import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';

import '../support/dial_preview_panel.dart';
import '../support/fake_provider.dart';
import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  testWidgets(
    'dial commits the last preview without relying on device feedback',
    (tester) async {
      final provider = FakeProvider(
        enabledControls: true,
        enableContentFeedback: false,
      );
      final app = await AppBootstrap.initialize(
        storage: MemoryStorage(),
        registry: ProviderRegistry()..register(provider),
      );
      await app.connection.connect(tv);
      final panel = DialPreviewPanel(app);
      final item = GridItem(
        id: 'dial',
        definitionId: 'volumeDial',
        x: 0,
        y: 0,
        w: 2,
        h: 2,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox.square(
              dimension: 200,
              child: ElementRenderer(
                item: item,
                model: GridRemoteViewModel(panel),
              ),
            ),
          ),
        ),
      );
      final center = tester.getCenter(find.byType(CircularProgressIndicator));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(0, 45));
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      expect(panel.previews.last, closeTo(50, .01));
      expect(provider.last!.volumeControl.level, 20);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(provider.last!.volumeControl.level, 50);

      final cancelled = await tester.startGesture(center);
      await cancelled.moveBy(const Offset(45, 0));
      await cancelled.moveBy(const Offset(20, 0));
      await cancelled.cancel();
      await tester.pumpAndSettle();
      expect(provider.last!.volumeControl.level, 50);
      await tester.pumpWidget(const SizedBox.shrink());
      unawaited(app.dispose());
      await tester.pump();
    },
  );
}
