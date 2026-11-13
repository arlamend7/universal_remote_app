import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/presentation/views/remote/viewmodels/remote_viewmodel.dart';

import '../support/memory_storage.dart';

/// Pumps one item on a 4-column grid of 90 px cells and returns its card.
Future<Rect> pumpItem(WidgetTester tester, GridItem item) async {
  final app = await AppBootstrap.initialize(storage: MemoryStorage());
  const cell = 90.0;
  const gap = SquareGridMetrics.gap;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 4 * cell + 3 * gap,
            child: GridRemoteCanvas(
              remote: RemoteViewModel(app),
              layout: GridLayout([item], configuredRows: item.y + item.h),
              columns: 4,
              rows: item.y + item.h,
              previewData: RemotePreviewData.example,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.getRect(find.byType(GridRemoteItem));
}

GridItem rocker(int w, int h, ItemAxis position) => GridItem(
  id: 'rocker',
  definitionId: 'volumeRocker',
  x: 0,
  y: 0,
  w: w,
  h: h,
  position: position,
);

void main() {
  final louder = find.byTooltip('Louder');
  final lower = find.byTooltip('Lower');

  void expectCentered(WidgetTester tester, Rect card) {
    final group = tester.getRect(louder).expandToInclude(tester.getRect(lower));
    expect(group.center.dx, moreOrLessEquals(card.center.dx, epsilon: .5));
    expect(group.center.dy, moreOrLessEquals(card.center.dy, epsilon: .5));
  }

  testWidgets('an enlarged vertical rocker stays a centered column', (
    tester,
  ) async {
    final card = await pumpItem(tester, rocker(2, 4, ItemAxis.vertical));
    expect(tester.getCenter(louder).dy, lessThan(tester.getCenter(lower).dy));
    expect(tester.getCenter(louder).dx, tester.getCenter(lower).dx);
    expect(tester.getSize(louder).width, lessThan(card.width / 2 + 1));
    expectCentered(tester, card);
  });

  testWidgets('an enlarged horizontal rocker stays a centered row', (
    tester,
  ) async {
    final card = await pumpItem(tester, rocker(2, 4, ItemAxis.horizontal));
    expect(tester.getCenter(louder).dx, lessThan(tester.getCenter(lower).dx));
    expect(tester.getCenter(louder).dy, tester.getCenter(lower).dy);
    expect(tester.getSize(louder).height, lessThan(card.height / 2));
    expectCentered(tester, card);
  });

  testWidgets('a rocker switched to horizontal (4 × 2) is a centered row', (
    tester,
  ) async {
    final vertical = rocker(2, 4, ItemAxis.vertical);
    final card = await pumpItem(
      tester,
      vertical.withPosition(ItemAxis.horizontal),
    );
    expect(card.width, greaterThan(card.height));
    expect(tester.getCenter(louder).dx, lessThan(tester.getCenter(lower).dx));
    expect(tester.getCenter(louder).dy, tester.getCenter(lower).dy);
    expectCentered(tester, card);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the card follows the saved size; Position only arranges', (
    tester,
  ) async {
    final vertical = await pumpItem(tester, rocker(2, 4, ItemAxis.vertical));
    final horizontal = await pumpItem(
      tester,
      rocker(2, 4, ItemAxis.horizontal),
    );
    expect(horizontal, vertical);
  });

  testWidgets('a square pad keeps its geometry centered in a wide card', (
    tester,
  ) async {
    final card = await pumpItem(
      tester,
      GridItem(id: 'pad', definitionId: 'arrowPad', x: 0, y: 0, w: 4, h: 3),
    );
    final up = tester.getCenter(find.byTooltip('Up'));
    final down = tester.getCenter(find.byTooltip('Down'));
    final left = tester.getCenter(find.byTooltip('Left'));
    final right = tester.getCenter(find.byTooltip('Right'));
    expect(up.dx, moreOrLessEquals(card.center.dx, epsilon: .5));
    expect(down.dx, moreOrLessEquals(card.center.dx, epsilon: .5));
    expect(left.dy, moreOrLessEquals(right.dy, epsilon: .5));
    expect(
      (down.dy - up.dy),
      moreOrLessEquals(right.dx - left.dx, epsilon: .5),
      reason: 'The pad stays square, not stretched to the card.',
    );
    expect(
      (left.dx + right.dx) / 2,
      moreOrLessEquals(card.center.dx, epsilon: .5),
    );
  });
}
