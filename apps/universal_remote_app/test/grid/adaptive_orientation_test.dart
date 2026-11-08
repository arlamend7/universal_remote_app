import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

import '../support/no_controller_panel_session.dart';

/// Only what the rocker reads; every other member is unsupported.
final class _Panel implements RemotePanel {
  @override
  RemotePanelSession get connection => const NoControllerPanelSession();

  @override
  bool get ready => true;
  @override
  bool get offline => false;
  @override
  bool supports(RemoteCapability capability) => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    '${invocation.memberName} is not part of this fake',
  );
}

void main() {
  final rocker = RemoteItemRegistry.resolve('volumeRocker');

  test('a rocker runs along whichever side is longer', () {
    expect(rocker.axisFor(1, 2), ItemAxis.vertical);
    expect(rocker.axisFor(2, 1), ItemAxis.horizontal);
    expect(rocker.axisFor(2, 2), rocker.axis);
  });

  test('the long side must hold every button; the short side may be 1', () {
    expect(rocker.accepts(1, 2), isTrue);
    expect(rocker.accepts(2, 1), isTrue);
    expect(rocker.accepts(3, 1), isTrue);
    expect(rocker.accepts(1, 1), isFalse);
    final display = RemoteItemRegistry.resolve('volumeDisplayRocker');
    expect(display.accepts(3, 1), isTrue);
    expect(display.accepts(2, 1), isFalse);
    expect(display.accepts(1, 3), isTrue);
  });

  test('fixed layouts keep their own minimums', () {
    final strip = RemoteItemRegistry.resolve('navigationStrip');
    expect(strip.accepts(2, 1), isTrue);
    expect(strip.accepts(1, 2), isFalse);
  });

  testWidgets('horizontal rockers put "less" on the left', (tester) async {
    Future<void> pump(int w, int h) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 240,
            child: ElementStrip(
              definition: rocker,
              item: GridItem(
                id: 'r',
                definitionId: 'volumeRocker',
                x: 0,
                y: 0,
                w: w,
                h: h,
              ),
              model: GridRemoteViewModel(_Panel()),
            ),
          ),
        ),
      ),
    );

    await pump(2, 1);
    expect(
      tester.getCenter(find.byTooltip('Lower')).dx,
      lessThan(tester.getCenter(find.byTooltip('Louder')).dx),
    );
    await pump(1, 2);
    expect(
      tester.getCenter(find.byTooltip('Louder')).dy,
      lessThan(tester.getCenter(find.byTooltip('Lower')).dy),
    );
  });
}
