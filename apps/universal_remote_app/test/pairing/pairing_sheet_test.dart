import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:universal_remote_app/presentation/views/pairing/widgets/pairing_code_card.dart';

import '../support/recording_pairing_receiver.dart';

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
}
