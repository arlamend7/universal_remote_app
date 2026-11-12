import 'package:flutter_test/flutter_test.dart';

Future<void> startNearbySearch(WidgetTester tester) async {
  final welcome = find.text('Find Nearby TVs');
  await tester.tap(
    welcome.evaluate().isNotEmpty ? welcome : find.text('Connect'),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('My TV is on'));
  await tester.pump();
  await tester.tap(find.text('Search for devices'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}
