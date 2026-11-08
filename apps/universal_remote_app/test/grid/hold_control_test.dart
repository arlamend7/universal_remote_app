import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_ui/remote_ui.dart';

void main() {
  testWidgets('hold-to-repeat stops on release and disposal', (tester) async {
    var count = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 100,
            child: GridButton(
              label: 'Louder',
              icon: Icons.add,
              repeat: true,
              onPressed: () => count++,
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(GridButton)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 700));
    expect(count, greaterThan(1));
    await gesture.up();
    await tester.pump();
    final stopped = count;
    await tester.pump(const Duration(seconds: 1));
    expect(count, stopped);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(count, stopped);
  });
}
