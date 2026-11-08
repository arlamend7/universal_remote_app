import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/data/devices/mappers/saved_device_mapper.dart';

void main() {
  test('legacy LG profiles retain layout data and new profiles round-trip category and capabilities', () {
    final mapper = SavedDeviceMapper(
      categoryForProvider: (_) => DeviceCategory.television,
    );
    final legacy = mapper.fromJson({
      'id': 'tv',
      'name': 'TV',
      'providerId': 'lg.webos',
      'stableIdentity': true,
      'endpoints': ['wss://192.168.1.20:3001'],
      'metadata': {'remoteGrid.v2': 'existing layout'},
    });
    expect(legacy.category, DeviceCategory.television);
    expect(legacy.capabilities, isEmpty);
    expect(legacy.metadata['remoteGrid.v2'], 'existing layout');

    final ac = RemoteDevice(
      id: 'ac',
      name: 'AC',
      category: DeviceCategory.airConditioner,
      capabilities: {RemoteCapability.climate},
    );
    final encoded = mapper.toJson(ac);
    (encoded['capabilities'] as List<String>).add('futureCapability');
    final restored = mapper.fromJson(encoded);
    expect(restored.category, DeviceCategory.airConditioner);
    expect(restored.capabilities, {RemoteCapability.climate});
    expect(restored.endpoints, isEmpty);
  });
}
