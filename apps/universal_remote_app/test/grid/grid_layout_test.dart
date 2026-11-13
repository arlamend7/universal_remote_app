import 'package:remote_core/remote_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:remote_ui/remote_ui.dart';

import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  test(
    'page settings and deletion preserve other pages and round trip',
    () async {
      final app = await AppBootstrap.initialize(storage: MemoryStorage());
      final editor = GridEditorViewModel(
        app.grids,
        tv,
        initial: GridLayout(
          [
            GridItem(id: 'first', definitionId: 'mute', x: 0, y: 0, w: 1, h: 1),
            GridItem(
              id: 'second',
              definitionId: 'mute',
              x: 5,
              y: 1,
              w: 1,
              h: 1,
            ),
            GridItem(id: 'third', definitionId: 'mute', x: 9, y: 2, w: 1, h: 1),
          ],
          columns: 12,
          configuredRows: 8,
          pageStarts: [0, 4, 8],
        ),
      );
      editor.selectPage(4);
      editor.setDimensions(5, 10, cellSize: 72);
      final layout = GridLayout.decode(editor.draft.encode());
      expect(layout.pageStarts, [0, 4, 9]);
      expect(layout.pageColumns(1), 5);
      expect(layout.pageRows(1), 10);
      expect(layout.pageCellSize(1), 72);
      expect(layout.pageRows(0), 8);
      expect(layout.pageRows(2), 8);
      expect(layout.pageCellSize(2), 66.8);
      expect(layout.pageLayout(2).items.single.x, 1);
      editor.deletePage();
      expect(editor.draft.items.map((item) => item.id), ['first', 'third']);
      expect(editor.draft.pageLayout(1).items.single.x, 1);
      editor.deletePage();
      expect(editor.draft.pageStarts, [0, 4]);
      editor.undo();
      expect(editor.draft.encode(), layout.encode());
      editor.dispose();
      await app.dispose();
    },
  );

  test('Position persists independently of the saved size', () {
    final rocker = GridItem(
      id: 'rocker',
      definitionId: 'volumeRocker',
      x: 0,
      y: 0,
      w: 2,
      h: 4,
      position: ItemAxis.horizontal,
    );
    final restored = GridLayout.decode(GridLayout([rocker]).encode())
        .items
        .single;
    expect(restored.position, ItemAxis.horizontal);
    expect((restored.w, restored.h), (2, 4));
    expect(restored.arrangement, ItemAxis.horizontal);

    final unset = GridLayout.decode(
      GridLayout([rocker.withoutPosition()]).encode(),
    ).items.single;
    expect(unset.position, isNull);
    expect(unset.arrangement, ItemAxis.vertical);
    expect((unset.w, unset.h), (2, 4));
  });

  test(
    'duplicates, snapping, collisions, resize and undo preserve a valid draft',
    () async {
      final app = await AppBootstrap.initialize(storage: MemoryStorage());
      final editor = GridEditorViewModel(
        app.grids,
        tv,
        initial: GridLayout([]),
      );
      final first = editor.add('volumeRocker')!;
      final second = editor.add('volumeRocker')!;
      expect(first.id, isNot(second.id));
      expect(GridGeometry.overlaps(first, second), false);
      editor.update(second.copy(x: first.x, y: first.y));
      expect(editor.error, isNotNull);
      expect(editor.draft.items.last.x, second.x);
      editor.update(second.copy(x: 0, w: 4));
      expect(editor.error, isNotNull);
      editor.remove(first.id);
      editor.undo();
      expect(editor.draft.items, hasLength(2));
      editor.redo();
      expect(editor.draft.items, hasLength(1));
      editor.dispose();
      await app.dispose();
    },
  );
  test('group coordinates, bounds, nested groups and versioned serialization are checked', () {
    final child = GridItem(
      id: 'volume',
      definitionId: 'volumeRocker',
      x: 0,
      y: 0,
      w: 1,
      h: 2,
    );
    final group = GridItem(
      id: 'audio',
      definitionId: 'group',
      x: 0,
      y: 0,
      w: 2,
      h: 3,
      children: [child],
    );
    expect(GridGeometry.valid([group]), true);
    expect(
      GridLayout.decode(GridLayout([group]).encode())
          .items
          .single
          .children
          .single
          .definitionId,
      'volumeRocker',
    );
    expect(GridGeometry.valid([group.copy(w: 1, h: 1)]), false);
    expect(
      GridGeometry.valid([
        group.copy(children: [group]),
      ]),
      false,
    );
    expect(GridGeometry.valid([group, group]), false);
  });
  test(
    'saving preserves existing profile metadata and the grid survives reload',
    () async {
      final memory = MemoryStorage();
      final app = await AppBootstrap.initialize(storage: memory);
      await app.savedDevices.save(
        copyDevice(tv, metadata: {'remoteLayout.v1': 'legacy layout'}),
      );
      final draft = GridEditorViewModel(app.grids, tv);
      draft.add('volumeRocker');
      expect(app.grids.forDevice(tv), isNull);
      expect(await draft.save(), true);
      expect(app.grids.forDevice(tv)!.items.last.definitionId, 'volumeRocker');
      expect(
        app.savedDevices.devices.value.single.metadata['remoteLayout.v1'],
        'legacy layout',
      );
      draft.dispose();
      await app.dispose();
      final reloaded = await AppBootstrap.initialize(storage: memory);
      expect(reloaded.grids.forDevice(tv), isNotNull);
      expect(
        reloaded.grids.forDevice(tv)!.items.last.definitionId,
        'volumeRocker',
      );
      await reloaded.dispose();
    },
  );
}
