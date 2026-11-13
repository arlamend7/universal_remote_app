import 'package:remote_core/remote_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/data/devices/repositories/saved_device_repository.dart';
import 'package:remote_ui/remote_ui.dart';

import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  test('saves dashboards separately and reloads them without rewriting the profile', () async {
    final storage = MemoryStorage();
    await SavedDeviceRepository(storage)
        .saveRegistered([const DeviceRegistry().fromProfile(tv)]);
    final profileBytes = storage.values['saved-devices.v2'];
    final app = await AppBootstrap.initialize(storage: storage);
    final grid = GridLayout([
      GridItem(
        id: 'volume',
        definitionId: 'volumeRocker',
        x: 0,
        y: 0,
        w: 2,
        h: 1,
        position: ItemAxis.horizontal,
        style: const RemoteItemStyle(background: 0xff243531, opacity: .65),
        elementStyles: const {'volume_up': RemoteElementStyle(iconSize: 32)},
      ),
    ]);
    await app.grids.save(tv, grid);
    expect(storage.values['dashboards.v2'], isNotNull);
    expect(storage.values['saved-devices.v2'], profileBytes);
    await app.dispose();

    final reloaded = await AppBootstrap.initialize(storage: storage);
    final item = reloaded.grids.forDevice(tv)!.items.single;
    expect(item.definitionId, 'volumeRocker');
    expect(item.position, ItemAxis.horizontal);
    expect((item.w, item.h), (2, 1));
    expect(item.style.opacity, .65);
    expect(item.elementStyles['volume_up']!.iconSize, 32);
    await reloaded.dispose();
  });

  test(
    'an unknown definition keeps its identifier and place on the dashboard',
    () {
      const encoded =
          '{"version":2,"items":[{"id":"future","definitionId":"futureControl",'
          '"x":0,"y":0,"w":2,"h":2}]}';
      final layout = GridLayout.decode(encoded);
      expect(layout.items.single.definitionId, 'futureControl');
      expect(RemoteItemRegistry.isRegistered('futureControl'), isFalse);
      expect(
        RemoteItemRegistry.resolve('futureControl').layout,
        isA<UnavailableLayout>(),
      );
      expect(GridGeometry.valid(layout.items), isTrue);
      expect(layout.encode(), contains('"definitionId":"futureControl"'));
    },
  );
}
