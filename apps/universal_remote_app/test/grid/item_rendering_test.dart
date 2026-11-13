import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/presentation/views/remote/viewmodels/remote_viewmodel.dart';

import '../support/memory_storage.dart';

/// Every registered control renders at its minimum and an enlarged size, in
/// each Position it supports, without overflow or layout errors.
void main() {
  testWidgets('every registered item lays out at every size and Position', (
    tester,
  ) async {
    final app = await AppBootstrap.initialize(storage: MemoryStorage());
    final remote = RemoteViewModel(app);
    for (final definition in RemoteItemRegistry.definitions) {
      for (final item in _variants(definition)) {
        await tester.pumpWidget(_canvas(remote, item));
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason:
              '${definition.id} ${item.w}×${item.h} ${item.arrangement.name}',
        );
      }
    }
  });
}

Iterable<GridItem> _variants(RemoteItemDefinition<Object> definition) sync* {
  final sizes = {
    (definition.minimumWidth, definition.minimumHeight),
    (
      math.min(definition.minimumWidth + 2, GridLayout.defaultColumns),
      definition.minimumHeight + 2,
    ),
  };
  final positions = definition.supportsPosition
      ? ItemAxis.values
      : const <ItemAxis?>[null];
  for (final (w, h) in sizes) {
    for (final position in positions) {
      yield GridItem(
        id: definition.id,
        definitionId: definition.id,
        x: 0,
        y: 0,
        w: math.max(w, definition.minimumWidth),
        h: h,
        position: position,
      );
    }
  }
}

Widget _canvas(RemotePanel remote, GridItem item) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 4 * 90 + 3 * SquareGridMetrics.gap,
        child: SingleChildScrollView(
          child: GridRemoteCanvas(
            remote: remote,
            previewData: RemotePreviewData.example,
            columns: math.max(4, item.w),
            rows: item.h,
            layout: GridLayout(
              [item],
              columns: math.max(4, item.w),
              configuredRows: item.h,
            ),
          ),
        ),
      ),
    ),
  ),
);
