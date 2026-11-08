import 'package:remote_core/remote_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/data/devices/repositories/saved_device_repository.dart';
import 'package:remote_ui/remote_ui.dart';

import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  test(
    'moves legacy dashboards to separate storage without rewriting the profile',
    () async {
      final storage = MemoryStorage();
      final grid = GridLayout([
        GridItem(
          id: 'volume',
          kind: GridWidgetKind.volumeRocker,
          x: 0,
          y: 0,
          w: 2,
          h: 1,
          orientation: ItemOrientation.horizontal,
          style: const RemoteItemStyle(background: 0xff243531, opacity: .65),
          elementStyles: const {'volume_up': RemoteElementStyle(iconSize: 32)},
        ),
      ]);
      expect(GridGeometry.valid(grid.items), isTrue);
      final legacy = copyDevice(
        tv,
        metadata: {'remoteGrid.active': 'true', 'remoteGrid.v2': grid.encode()},
      );
      await SavedDeviceRepository(storage).save([legacy]);
      final profileBytes = storage.values['saved-devices.v1'];
      final app = await AppBootstrap.initialize(storage: storage);
      expect(storage.values['dashboards.v1'], isNotNull);
      final migrated = app.grids.forDevice(tv)!.items.single;
      expect(migrated.layoutKind, GridWidgetKind.volumeHorizontal);
      expect(migrated.quarterTurns, 0);
      expect(migrated.style.opacity, .65);
      expect(migrated.elementStyles['volume_up']!.iconSize, 32);
      await app.grids.save(tv, GridLayout([]));
      expect(storage.values['saved-devices.v1'], profileBytes);
      await app.dispose();

      final reloaded = await AppBootstrap.initialize(storage: storage);
      expect(reloaded.grids.forDevice(tv)!.items, isEmpty);
      await reloaded.dispose();
    },
  );

  test(
    'an unknown definition keeps its identifier and place on the dashboard',
    () {
      const encoded =
          '{"version":2,"items":[{"id":"future","kind":"futureControl",'
          '"x":0,"y":0,"w":2,"h":2}]}';
      final layout = GridLayout.decode(encoded);
      expect(layout.items.single.kind, GridWidgetKind.unknown);
      expect(GridGeometry.valid(layout.items), isTrue);
      expect(layout.encode(), contains('"kind":"futureControl"'));
    },
  );
}
