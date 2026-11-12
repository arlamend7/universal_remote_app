import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/data/devices/mappers/saved_device_mapper.dart';

void main() {
  const mapper = SavedDeviceMapper();

  RemoteDevice androidTv() => RemoteDevice(
    id: 'android-tv-fingerprint',
    name: 'Living room',
    providerId: 'android.tv',
    endpoints: [Uri.parse('tls://192.168.1.60:6466')],
    stableIdentity: true,
    metadata: const {
      DeviceMetadataKeys.verifiedPeerIdentity: 'fingerprint',
      DeviceMetadataKeys.integrationId: 'android.tv.remote-v2',
    },
  );

  test('the reported vendor, model and service evidence persist', () {
    final software = DeviceSoftwareInformation(
      source: DeviceInformationSource.authenticatedSession,
      manufacturer: 'TCL',
      model: 'Smart TV Pro',
      operatingSystem: 'Android TV',
      protocolVersion: 'Remote v2',
      identifiedAt: DateTime.utc(2026, 11, 12),
      raw: const {
        'remoteServicePackage': 'com.google.android.tv.remote.service',
        'remoteServiceVersion': '5.2.473254133',
      },
    );
    final device = copyDevice(
      androidTv(),
      manufacturer: 'TCL',
      model: 'Smart TV Pro',
      softwareInformation: software,
      metadata: {
        ...androidTv().metadata,
        DeviceMetadataKeys.correlationIdentity: 'aa:bb:cc:dd:ee:ff',
      },
    );
    final restored = mapper.fromJson(mapper.toJson(device));
    expect(restored.id, device.id);
    expect(restored.providerId, 'android.tv');
    expect(restored.manufacturer, 'TCL');
    expect(restored.model, 'Smart TV Pro');
    expect(restored.endpoints, device.endpoints);
    expect(restored.metadata, device.metadata);
    expect(restored.softwareInformation?.toJson(), software.toJson());
    expect(restored.softwareInformation?.operatingSystemVersion, isNull);
    expect(restored.softwareInformation?.firmwareVersion, isNull);
  });

  test('a device saved before identification keeps its identity', () {
    final encoded = mapper.toJson(androidTv())
      ..remove('manufacturer')
      ..remove('model')
      ..remove('softwareInformation');
    final restored = mapper.fromJson(encoded);
    expect(restored.id, 'android-tv-fingerprint');
    expect(restored.manufacturer, isNull);
    expect(restored.model, isNull);
    expect(
      restored.metadata[DeviceMetadataKeys.verifiedPeerIdentity],
      'fingerprint',
    );
    expect(restored.stableIdentity, isTrue);
  });
}
