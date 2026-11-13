import 'package:flutter_test/flutter_test.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';

import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  RemoteItemDefinition<Object> definition(String id) =>
      RemoteItemRegistry.resolve(id);

  group('default Position comes from the minimum size only', () {
    test('a 1 × 3 minimum starts vertical', () {
      final rocker = definition('volumeDisplayRocker');
      expect((rocker.minimumWidth, rocker.minimumHeight), (1, 3));
      expect(rocker.defaultPosition, ItemAxis.vertical);
      expect(rocker.supportsPosition, isTrue);
    });

    test('a 3 × 1 minimum starts horizontal', () {
      final transport = definition('transport');
      expect((transport.minimumWidth, transport.minimumHeight), (3, 1));
      expect(transport.defaultPosition, ItemAxis.horizontal);
      expect(transport.supportsPosition, isTrue);
    });

    test('square minimums (2 × 2, 1 × 1) have no Position', () {
      for (final id in ['volumeDial', 'power']) {
        final square = definition(id);
        expect(square.minimumWidth, square.minimumHeight, reason: id);
        expect(square.defaultPosition, isNull, reason: id);
        expect(square.supportsPosition, isFalse, reason: id);
      }
    });

    test('every registered definition follows the rule', () {
      for (final item in RemoteItemRegistry.definitions) {
        final wide = item.minimumWidth > item.minimumHeight;
        final tall = item.minimumHeight > item.minimumWidth;
        final expected = wide
            ? ItemAxis.horizontal
            : tall
            ? ItemAxis.vertical
            : null;
        expect(item.defaultPosition, expected, reason: item.id);
        if (item.supportsPosition) {
          expect(expected, isNotNull, reason: item.id);
        }
        expect(
          item.accepts(item.minimumWidth, item.minimumHeight),
          isTrue,
          reason: item.id,
        );
      }
    });

    test('pads, dials and touch surfaces keep their own geometry', () {
      for (final id in ['directionPad', 'arrowPad', 'volumeDial', 'touchpad']) {
        expect(definition(id).supportsPosition, isFalse, reason: id);
      }
    });

    test('a square item enlarged to a rectangle still has no Position', () {
      final dial = GridItem(
        id: 'dial',
        definitionId: 'volumeDial',
        x: 0,
        y: 0,
        w: 4,
        h: 2,
      );
      expect(dial.definition.supportsPosition, isFalse);
      expect(dial.arrangement, dial.definition.axis);
    });
  });

  group('size and Position stay independent in the editor', () {
    late GridEditorViewModel editor;

    Future<void> edit(List<GridItem> items) async {
      final app = await AppBootstrap.initialize(storage: MemoryStorage());
      editor = GridEditorViewModel(
        app.grids,
        tv,
        initial: GridLayout(items, configuredRows: 8),
      );
    }

    GridItem item(String id) =>
        editor.draft.items.firstWhere((item) => item.id == id);

    GridItem rocker(int w, int h, ItemAxis position) => GridItem(
      id: 'rocker',
      definitionId: 'volumeRocker',
      x: 0,
      y: 0,
      w: w,
      h: h,
      position: position,
    );

    test('vertical 2 × 4 resized to 4 × 4 stays vertical', () async {
      await edit([rocker(2, 4, ItemAxis.vertical)]);
      editor.resize(item('rocker'), 4, 4);
      expect((item('rocker').w, item('rocker').h), (4, 4));
      expect(item('rocker').arrangement, ItemAxis.vertical);
    });

    test('horizontal 4 × 2 resized to 2 × 4 stays horizontal', () async {
      await edit([rocker(4, 2, ItemAxis.horizontal)]);
      editor.resize(item('rocker'), 2, 4);
      expect((item('rocker').w, item('rocker').h), (2, 4));
      expect(item('rocker').arrangement, ItemAxis.horizontal);
    });

    test('vertical 2 × 4 switched to horizontal keeps 2 × 4', () async {
      await edit([rocker(2, 4, ItemAxis.vertical)]);
      editor.replace(item('rocker').copy(position: ItemAxis.horizontal));
      expect(item('rocker').arrangement, ItemAxis.horizontal);
      expect(
        (
          item('rocker').x,
          item('rocker').y,
          item('rocker').w,
          item('rocker').h,
        ),
        (0, 0, 2, 4),
      );
    });

    test('horizontal 3 × 3 switched to vertical keeps 3 × 3', () async {
      await edit([
        GridItem(
          id: 'transport',
          definitionId: 'transport',
          x: 1,
          y: 2,
          w: 3,
          h: 3,
          position: ItemAxis.horizontal,
        ),
      ]);
      editor.replace(item('transport').copy(position: ItemAxis.vertical));
      final switched = item('transport');
      expect(switched.arrangement, ItemAxis.vertical);
      expect((switched.x, switched.y, switched.w, switched.h), (1, 2, 3, 3));
    });

    test('a 2 × 2 minimum rejects 1 × 2 and accepts 4 × 4', () async {
      await edit([
        GridItem(
          id: 'inputs',
          definitionId: 'inputGrid',
          x: 0,
          y: 0,
          w: 2,
          h: 2,
        ),
      ]);
      expect(editor.canReplace(item('inputs').copy(w: 1)), isFalse);
      editor.resize(item('inputs'), 1, 2);
      expect((item('inputs').w, item('inputs').h), (2, 2));
      expect(editor.error, contains('does not support 1 × 2'));
      editor.resize(item('inputs'), 4, 4);
      expect((item('inputs').w, item('inputs').h), (4, 4));
      expect(editor.error, isNull);
    });

    test('new items start with the default Position', () async {
      await edit([]);
      final added = editor.add('volumeDisplayRocker')!;
      expect(added.position, ItemAxis.vertical);
      final square = editor.add('volumeDial')!;
      expect(square.position, isNull);
    });
  });
}
