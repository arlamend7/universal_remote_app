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

    test('vertical 2 × 4 switched to horizontal becomes 4 × 2', () async {
      await edit([rocker(2, 4, ItemAxis.vertical)]);
      expect(
        editor.changePosition(item('rocker'), ItemAxis.horizontal),
        isTrue,
      );
      final switched = item('rocker');
      expect(switched.arrangement, ItemAxis.horizontal);
      expect((switched.x, switched.y, switched.w, switched.h), (0, 0, 4, 2));
    });

    test('horizontal 4 × 2 switched to vertical becomes 2 × 4', () async {
      await edit([rocker(4, 2, ItemAxis.horizontal)]);
      editor.changePosition(item('rocker'), ItemAxis.vertical);
      expect((item('rocker').w, item('rocker').h), (2, 4));
      expect(item('rocker').arrangement, ItemAxis.vertical);
    });

    test(
      'vertical 1 × 3 resized to 4 × 4 stays vertical until switched',
      () async {
        await edit([
          GridItem(
            id: 'rocker',
            definitionId: 'volumeDisplayRocker',
            x: 0,
            y: 0,
            w: 1,
            h: 3,
            position: ItemAxis.vertical,
          ),
        ]);
        editor.resize(item('rocker'), 4, 4);
        expect((item('rocker').w, item('rocker').h), (4, 4));
        expect(item('rocker').arrangement, ItemAxis.vertical);
        editor.changePosition(item('rocker'), ItemAxis.horizontal);
        expect((item('rocker').w, item('rocker').h), (4, 4));
        expect(item('rocker').arrangement, ItemAxis.horizontal);
      },
    );

    test('repeated switching never drifts', () async {
      await edit([rocker(1, 3, ItemAxis.vertical)]);
      for (final next in [
        ItemAxis.horizontal,
        ItemAxis.vertical,
        ItemAxis.horizontal,
        ItemAxis.vertical,
      ]) {
        expect(editor.changePosition(item('rocker'), next), isTrue);
      }
      final back = item('rocker');
      expect((back.x, back.y, back.w, back.h), (0, 0, 1, 3));
      expect(back.arrangement, ItemAxis.vertical);
    });

    test('the effective minimum swaps; the canonical one does not', () async {
      await edit([rocker(1, 2, ItemAxis.vertical)]);
      expect(item('rocker').minimumSize, (width: 1, height: 2));
      editor.changePosition(item('rocker'), ItemAxis.horizontal);
      expect((item('rocker').w, item('rocker').h), (2, 1));
      expect(item('rocker').minimumSize, (width: 2, height: 1));
      expect(editor.canReplace(item('rocker').copy(w: 1, h: 2)), isFalse);
      editor.resize(item('rocker'), 1, 1);
      expect((item('rocker').w, item('rocker').h), (2, 1));
      editor.changePosition(item('rocker'), ItemAxis.vertical);
      expect(item('rocker').minimumSize, (width: 1, height: 2));
      final definition = item('rocker').definition;
      expect((definition.minimumWidth, definition.minimumHeight), (1, 2));
      expect(definition.minimumFor(ItemAxis.horizontal), (width: 2, height: 1));
    });

    test('a colliding swap moves to the nearest free slot only', () async {
      await edit([
        rocker(2, 4, ItemAxis.vertical),
        GridItem(id: 'mute', definitionId: 'mute', x: 2, y: 0, w: 1, h: 1),
      ]);
      expect(
        editor.changePosition(item('rocker'), ItemAxis.horizontal),
        isTrue,
      );
      final moved = item('rocker');
      expect((moved.x, moved.y, moved.w, moved.h), (0, 1, 4, 2));
      expect((item('mute').x, item('mute').y), (2, 0));
      expect(GridGeometry.valid(editor.draft.items), isTrue);
    });

    test('a swap with no room is rejected and nothing changes', () async {
      await edit([
        GridItem(
          id: 'rocker',
          definitionId: 'volumeDisplayRocker',
          x: 0,
          y: 0,
          w: 1,
          h: 4,
          position: ItemAxis.vertical,
        ),
        for (var y = 0; y < 8; y++)
          GridItem(id: 'mute$y', definitionId: 'mute', x: 2, y: y, w: 1, h: 1),
      ]);
      final before = editor.draft.encode();
      expect(
        editor.changePosition(item('rocker'), ItemAxis.horizontal),
        isFalse,
      );
      expect(editor.error, contains('no room for a 4 × 1'));
      expect(editor.draft.encode(), before);
      expect((editor.draft.canvasColumns, editor.draft.rows), (4, 8));
    });

    test('square-minimum items never swap', () async {
      await edit([
        GridItem(
          id: 'dial',
          definitionId: 'volumeDial',
          x: 0,
          y: 0,
          w: 4,
          h: 2,
        ),
      ]);
      final dial = item('dial');
      expect(identical(dial.withPosition(ItemAxis.vertical), dial), isTrue);
      editor.changePosition(dial, ItemAxis.vertical);
      expect((item('dial').w, item('dial').h), (4, 2));
    });

    test(
      'save and reload keep Position and size without a second swap',
      () async {
        await edit([rocker(2, 4, ItemAxis.vertical)]);
        editor.changePosition(item('rocker'), ItemAxis.horizontal);
        final restored = GridLayout.decode(editor.draft.encode()).items.single;
        expect((restored.w, restored.h), (4, 2));
        expect(restored.arrangement, ItemAxis.horizontal);
        expect(GridGeometry.valid([restored]), isTrue);
      },
    );

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
      editor.changePosition(item('transport'), ItemAxis.vertical);
      final switched = item('transport');
      expect(switched.arrangement, ItemAxis.vertical);
      expect((switched.x, switched.y, switched.w, switched.h), (1, 2, 3, 3));
    });

    test('a 2 × 2 minimum clamps 1 × 2 and accepts 4 × 4', () async {
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
      expect(
        (item('inputs').w, item('inputs').h),
        (2, 2),
        reason: 'A request below the minimum clamps to the minimum.',
      );
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
