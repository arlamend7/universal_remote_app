import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/presentation/views/remote/viewmodels/remote_viewmodel.dart';

import '../support/memory_storage.dart';

void main() {
  BoxDecoration outer(WidgetTester tester) =>
      tester
              .widget<DecoratedBox>(
                find
                    .descendant(
                      of: find.byType(StyledItem),
                      matching: find.byType(DecoratedBox),
                    )
                    .first,
              )
              .decoration
          as BoxDecoration;

  Future<void> pumpStyled(WidgetTester tester, RemoteItemStyle style) =>
      tester.pumpWidget(
        MaterialApp(
          home: StyledItem(style: style, child: const Text('content')),
        ),
      );

  const styled = RemoteItemStyle(
    background: 0xff243531,
    showBorder: true,
    showBackground: true,
  );

  testWidgets('Show Background paints the chosen colour', (tester) async {
    await pumpStyled(tester, styled);
    expect(outer(tester).color, const Color(0xff243531));
  });

  testWidgets('Show Background without a colour paints the whole card', (
    tester,
  ) async {
    await pumpStyled(
      tester,
      const RemoteItemStyle(showBackground: true, cornerRadius: 1000),
    );
    final colors = Theme.of(tester.element(find.text('content'))).colorScheme;
    expect(outer(tester).color, StyledItem.cardColor(colors));
    expect(outer(tester).borderRadius, BorderRadius.circular(1000));
    final fill = find
        .descendant(
          of: find.byType(StyledItem),
          matching: find.byType(DecoratedBox),
        )
        .first;
    expect(
      tester.getRect(fill),
      tester.getRect(find.byType(StyledItem)),
      reason: 'The fill covers the whole outer container.',
    );
  });

  testWidgets('Show Background is off by default', (tester) async {
    await pumpStyled(tester, const RemoteItemStyle(showBorder: true));
    expect(outer(tester).color, isNull);
  });

  testWidgets('Show Background off leaves a transparent card with its border', (
    tester,
  ) async {
    await pumpStyled(tester, styled.copyWith(showBackground: false));
    expect(outer(tester).color, isNull);
    expect(outer(tester).border, isNotNull);
    expect(find.text('content'), findsOneWidget);
  });

  test('Show Background is saved only when turned on', () {
    expect(const RemoteItemStyle().toJson(), isEmpty);
    final on = const RemoteItemStyle().copyWith(showBackground: true);
    expect(on.isDefault, isFalse);
    expect(on.toJson(), {'showBackground': true});
    expect(RemoteItemStyle.fromJson(on.toJson()).showBackground, isTrue);
    expect(RemoteItemStyle.fromJson(const {}).showBackground, isFalse);
  });

  testWidgets('with the background on, the pad ring adds no second fill', (
    tester,
  ) async {
    final app = await AppBootstrap.initialize(storage: MemoryStorage());
    Future<List<Color?>> ringFills(bool background) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 4 * 90 + 3 * SquareGridMetrics.gap,
                child: GridRemoteCanvas(
                  remote: RemoteViewModel(app),
                  previewData: RemotePreviewData.example,
                  columns: 4,
                  rows: 3,
                  layout: GridLayout([
                    GridItem(
                      id: 'pad',
                      definitionId: 'directionPad',
                      x: 1,
                      y: 0,
                      w: 2,
                      h: 3,
                      style: RemoteItemStyle(showBackground: background),
                    ),
                  ], configuredRows: 3),
                ),
              ),
            ),
          ),
        ),
      );
      return tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(NavigationSurface),
              matching: find.byType(Container),
            ),
          )
          .map((ring) => (ring.decoration as BoxDecoration?)?.color)
          .toList();
    }

    final off = await ringFills(false);
    expect(off, contains(isNotNull), reason: 'The ring keeps its own fill.');
    final on = await ringFills(true);
    expect(on, everyElement(isNull));
  });

  testWidgets('a bordered item keeps its content inside the border', (
    tester,
  ) async {
    await pumpStyled(
      tester,
      const RemoteItemStyle(showBorder: true, borderWidth: 4),
    );
    final card = tester.getRect(find.byType(StyledItem));
    final text = tester.getRect(find.text('content'));
    expect(card.deflate(4).contains(text.topLeft), isTrue);
  });

  testWidgets(
    'a RemoteInfo border surrounds the whole cell, clear of the text',
    (tester) async {
      final app = await AppBootstrap.initialize(storage: MemoryStorage());
      const width = 3.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 4 * 90 + 3 * SquareGridMetrics.gap,
              child: GridRemoteCanvas(
                remote: RemoteViewModel(app),
                previewData: RemotePreviewData.example,
                columns: 4,
                rows: 2,
                layout: GridLayout([
                  GridItem(
                    id: 'level',
                    definitionId: 'volumeLevel',
                    x: 0,
                    y: 0,
                    w: 2,
                    h: 2,
                    elementStyles: const {
                      'current_volume': RemoteElementStyle(borderWidth: width),
                    },
                  ),
                ], configuredRows: 2),
              ),
            ),
          ),
        ),
      );
      final card = tester.getRect(find.byType(GridRemoteItem));
      final bordered = find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.position == DecorationPosition.foreground &&
            (widget.decoration as BoxDecoration).border != null,
      );
      expect(tester.getRect(bordered), card);
      final inner = card.deflate(width);
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        final rect = tester.getRect(find.byWidget(text));
        expect(inner.contains(rect.topLeft), isTrue, reason: text.data);
        expect(inner.contains(rect.bottomRight - const Offset(.1, .1)), isTrue);
      }
      expect(tester.takeException(), isNull);
    },
  );
}
