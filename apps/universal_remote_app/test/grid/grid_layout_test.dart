import 'package:remote_core/remote_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:remote_ui/remote_ui.dart';

import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  test('quarter turns persist with their rotated collision footprint', () {
    final rocker = GridItem(
      id: 'rocker',
      kind: GridWidgetKind.volumeRocker,
      x: 0,
      y: 0,
      w: 1,
      h: 2,
    );
    final neighbor = rocker.copy(id: 'neighbor', x: 1);
    for (final turns in [1, 2, 3]) {
      final rotated = rocker.copy(
        quarterTurns: turns,
        w: turns.isOdd ? 2 : 1,
        h: turns.isOdd ? 1 : 2,
      );
      expect(GridGeometry.valid([rotated]), isTrue);
      expect(GridGeometry.overlaps(rotated, neighbor), turns.isOdd);
      final restored = GridLayout.decode(GridLayout([rotated]).encode())
          .items
          .single;
      expect(restored.quarterTurns, turns);
      expect((restored.contentWidth, restored.contentHeight), (1, 2));
    }
    final legacy = GridLayout.decode(GridLayout([rocker]).encode());
    expect(legacy.items.single.quarterTurns, 0);
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
      final first = editor.add(GridWidgetKind.volumeRocker)!;
      final second = editor.add(GridWidgetKind.volumeRocker)!;
      expect(first.id, isNot(second.id));
      expect(GridGeometry.overlaps(first, second), false);
      editor.update(second.copy(x: first.x, y: first.y));
      expect(editor.error, isNotNull);
      expect(editor.draft.items.last.x, second.x);
      editor.update(second.copy(w: 4));
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
      kind: GridWidgetKind.volumeRocker,
      x: 0,
      y: 0,
      w: 1,
      h: 2,
    );
    final group = GridItem(
      id: 'audio',
      kind: GridWidgetKind.group,
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
          .kind,
      GridWidgetKind.volumeRocker,
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
      draft.add(GridWidgetKind.volumeRocker);
      expect(app.grids.forDevice(tv), isNull);
      expect(await draft.save(), true);
      expect(
        app.grids.forDevice(tv)!.items.last.kind,
        GridWidgetKind.volumeRocker,
      );
      expect(
        app.savedDevices.devices.value.single.metadata['remoteLayout.v1'],
        'legacy layout',
      );
      draft.dispose();
      await app.dispose();
      final reloaded = await AppBootstrap.initialize(storage: memory);
      expect(reloaded.grids.forDevice(tv), isNotNull);
      expect(
        reloaded.grids.forDevice(tv)!.items.last.kind,
        GridWidgetKind.volumeRocker,
      );
      await reloaded.dispose();
    },
  );
}
