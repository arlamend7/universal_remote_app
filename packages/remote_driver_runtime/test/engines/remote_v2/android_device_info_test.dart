import 'package:remote_driver_runtime/remote_v2.dart';
import 'package:test/test.dart';

void main() {
  test('reads model, vendor, service package and version', () {
    final info = AndroidDeviceInfo.parse(
      WireMessage.encode({
        1: 'Smart TV Pro',
        2: 'TCL',
        3: 1,
        4: '1',
        5: 'com.google.android.tv.remote.service',
        6: '5.2.473254133',
      }),
    )!;
    expect(info.model, 'Smart TV Pro');
    expect(info.vendor, 'TCL');
    expect(info.packageName, 'com.google.android.tv.remote.service');
    expect(info.appVersion, '5.2.473254133');
  });

  test('strips control characters, trims and bounds untrusted text', () {
    final info = AndroidDeviceInfo.parse(
      WireMessage.encode({
        1: '  BRAVIA\u0000\n 4K ',
        2: 'x' * 150,
        5: '\u0007',
      }),
    )!;
    expect(info.model, 'BRAVIA 4K');
    expect(info.vendor, hasLength(AndroidDeviceInfo.maximumLength));
    expect(info.packageName, isNull);
    expect(AndroidDeviceInfo.parse(WireMessage.encode({1: 'y' * 500})), isNull);
  });

  test('missing, empty or malformed device info stays unknown', () {
    expect(AndroidDeviceInfo.parse(null), isNull);
    expect(AndroidDeviceInfo.parse(7), isNull);
    expect(AndroidDeviceInfo.parse(<int>[]), isNull);
    expect(AndroidDeviceInfo.parse([0xff, 0xff]), isNull);
    expect(AndroidDeviceInfo.parse(WireMessage.encode({3: 1})), isNull);
  });
}
