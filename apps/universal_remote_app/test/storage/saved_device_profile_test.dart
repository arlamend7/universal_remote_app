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

  test(
    'software provenance persists independently of the device and driver IDs',
    () {
      const mapper = SavedDeviceMapper();
      final observation = DeviceSoftwareInformation(
        source: DeviceInformationSource.authenticatedSession,
        operatingSystem: 'Example OS',
        softwareVersion: 'R42-09',
        firmwareVersion: 'FW_009',
        identifiedAt: DateTime.utc(2026, 1, 1),
        raw: {'software': 'R42-09'},
      );
      final device = RemoteDevice(
        id: 'saved-tv',
        name: 'Living room',
        providerId: 'example.tv',
        metadata: {
          'managedDriverId': 'example.family',
          'verifiedPeerIdentity': 'existing-pin',
        },
      );
      final restored = mapper.fromJson(
        mapper.toJson(copyDevice(device, softwareInformation: observation)),
      );
      expect(restored.id, device.id);
      expect(restored.providerId, device.providerId);
      expect(restored.metadata, device.metadata);
      expect(restored.softwareInformation?.toJson(), observation.toJson());
      expect(
        restored.softwareInformation?.confidence,
        DeviceInformationConfidence.authenticated,
      );
      expect(restored.softwareInformation?.operatingSystemVersion, isNull);
    },
  );

  test('old display versions restore with unknown confidence and no inferred firmware', () {
    const mapper = SavedDeviceMapper();
    final encoded = mapper.toJson(
      RemoteDevice(
        id: 'old-tv',
        name: 'Old TV',
        metadata: {'softwareVersion': 'old value'},
      ),
    );
    encoded['softwareInformation'] = {'source': 'unrecognized'};
    final information = mapper.fromJson(encoded).softwareInformation!;
    expect(information.source, DeviceInformationSource.legacyCache);
    expect(information.confidence, DeviceInformationConfidence.unknown);
    expect(information.softwareVersion, 'old value');
    expect(information.firmwareVersion, isNull);
    expect(information.identifiedAt, isNull);
  });
}
