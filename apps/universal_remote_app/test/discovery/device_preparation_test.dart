import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_app/presentation/views/discovery/modals/device_preparation_sheet.dart';

void main() {
  for (final (size, scale) in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 1.4),
  ]) {
    testWidgets('preparation actions fit at $size and $scale', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const Scaffold(body: DevicePreparationSheet()),
        ),
      );
      final search = find.widgetWithText(FilledButton, 'Search for devices');
      expect(tester.widget<FilledButton>(search).onPressed, isNull);
      await tester.tap(find.text('My TV is on'));
      await tester.pump();
      expect(tester.widget<FilledButton>(search).onPressed, isNotNull);
      expect(search.hitTestable(), findsOneWidget);
      expect(find.text('Connect by IP').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
