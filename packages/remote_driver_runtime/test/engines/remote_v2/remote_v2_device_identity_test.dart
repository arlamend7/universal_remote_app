import 'package:remote_core/remote_core.dart';
import 'package:test/test.dart';

import 'support/paired_android_tv.dart';

/// Device info values follow the documented `RemoteDeviceInfo` shape; they are
/// not captures from real TVs.
void main() {
  for (final (vendor, model) in const [
    ('TCL', 'Smart TV Pro'),
    ('Google', 'Chromecast'),
    ('Sony', 'BRAVIA 4K VH2'),
  ]) {
    test('records the $vendor vendor and model the TV reports', () async {
      final tv = await pairedAndroidTv(
        deviceInfo: {
          1: model,
          2: vendor,
          5: 'com.google.android.tv.remote.service',
          6: '5.2.473254133',
        },
      );
      await tv.remote.connect();
      final device = tv.remote.device;
      final software = device.softwareInformation!;
      expect(device.manufacturer, vendor);
      expect(device.model, model);
      expect(software.manufacturer, vendor);
      expect(software.model, model);
      expect(software.operatingSystem, 'Android TV');
      expect(software.protocolVersion, 'Remote v2');
      expect(software.raw, {
        'remoteServicePackage': 'com.google.android.tv.remote.service',
        'remoteServiceVersion': '5.2.473254133',
      });
      expect(software.operatingSystemVersion, isNull);
      expect(software.firmwareVersion, isNull);
      expect(software.softwareVersion, isNull);
      expect(software.buildNumber, isNull);
      expect(tv.remote.state, DeviceConnectionState.connected);
    });
  }

  test('a TV without device info stays unknown and still connects', () async {
    final tv = await pairedAndroidTv();
    await tv.remote.connect();
    expect(tv.remote.device.manufacturer, isNull);
    expect(tv.remote.device.model, isNull);
    expect(tv.remote.device.softwareInformation?.raw, isEmpty);
    expect(tv.remote.state, DeviceConnectionState.connected);
  });

  test('a manufacturer already known for the device is preserved', () async {
    final tv = await pairedAndroidTv(
      manufacturer: 'Philips',
      deviceInfo: {1: 'OLED806', 2: 'TPV'},
    );
    await tv.remote.connect();
    expect(tv.remote.device.manufacturer, 'Philips');
    expect(tv.remote.device.softwareInformation?.manufacturer, 'TPV');
  });
}
