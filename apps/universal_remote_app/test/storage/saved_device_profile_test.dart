import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/data/devices/mappers/saved_device_mapper.dart';

void main() {
  test('V2 profiles round-trip category and known capabilities', () {
    const mapper = SavedDeviceMapper();
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
