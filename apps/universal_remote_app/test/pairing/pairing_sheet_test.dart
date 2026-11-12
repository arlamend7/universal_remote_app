import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:universal_remote_app/presentation/views/pairing/widgets/pairing_code_card.dart';

import '../support/recording_pairing_receiver.dart';
import '../support/test_device.dart';

void main() {
  testWidgets('pairing sheet accepts six characters with a small viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 540));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final receiver = RecordingPairingReceiver();
    var cancelled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAppModal<void>(
                context,
                builder: (sheetContext) => PairingCodeCard(
                  receiver: receiver,
                  deviceName: 'Living Room TV',
                  onCancel: () {
                    cancelled = true;
                    Navigator.pop(sheetContext);
                  },
                ),
              ),
              child: const Text('Open pairing'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open pairing'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Living Room TV'), findsOneWidget);
    final connect = find.widgetWithText(FilledButton, 'Connect');
    await tester.tap(connect);
    await tester.pumpAndSettle();
    expect(find.text('Enter all 6 characters.'), findsOneWidget);
    expect(receiver.submitted, isEmpty);

    await tester.enterText(find.byType(TextField), 'A1B2C3');
    await tester.tap(connect);
    await tester.pumpAndSettle();
    expect(receiver.submitted, ['A1B2C3']);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(cancelled, isTrue);
  });
  testWidgets(
    'full-page PIN confirmation stays reachable with the keyboard open',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final receiver = RecordingPairingReceiver();
      await tester.pumpWidget(
        MaterialApp(
          home: PairingCodeCard(
            receiver: receiver,
            deviceName: tv.name,
            setupDevice: tv,
            onCancel: () {},
          ),
        ),
      );
      expect(find.text('STEP 3 OF 4'), findsOneWidget);
      final field = find.byType(TextField);
      await tester.ensureVisible(field);
      await tester.enterText(field, 'A1B2C3');
      final confirm = find.text('Confirm code');
      await tester.ensureVisible(confirm);
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pump();
      expect(receiver.submitted, ['A1B2C3']);
      expect(tester.takeException(), isNull);
    },
  );
}
