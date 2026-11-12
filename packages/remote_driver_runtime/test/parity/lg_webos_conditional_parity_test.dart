import 'package:remote_driver_runtime/tv_provider_adapters.dart';
import 'package:test/test.dart';

import 'lg_webos_parity_fixture.dart';
import 'support/parity_golden.dart';
import 'support/parity_runner.dart';
import 'support/parity_step.dart';
import 'support/tv_parity_steps.dart';

void main() {
  test('legacy LG webOS conditional capabilities match the baseline', () async {
    final fixture = LgWebOsParityFixture(
      overrides: {
        'ssap://audio/getVolume': null,
        'ssap://com.webos.applicationManager/listApps': {
          'apps': [
            {'id': 'com.palm.app.settings', 'title': 'Settings'},
            {'id': 'com.webos.app.livetv', 'title': 'Live TV'},
          ],
        },
        'ssap://com.webos.applicationManager/getForegroundAppInfo': {
          'appId': 'com.webos.app.livetv',
        },
        'ssap://tv/getCurrentChannel': {
          'channelName': 'Local',
          'channelNumber': '7-1',
        },
        'ssap://tv/getExternalInputList': {'devices': <Object?>[]},
        'ssap://com.webos.service.btaudiosrc/getPairedDevices': null,
        'ssap://com.webos.service.update/getCurrentSWInformation': {
          'product_name': 'webOSTV 7.0',
          'model_name': 'OLED55C2',
          'sw_type': 'FIRMWARE',
          'major_ver': '03',
          'minor_ver': '20.11',
        },
      },
    );
    final provider = LgWebOsProvider(
      credentials: fixture.credentials,
      connector: fixture.connect,
    );
    final remote = provider.createController(fixture.device());
    addTearDown(remote.dispose);
    final names = {
      'connect',
      'evidence',
      'software',
      'readVolume',
      'toggleMute',
      'inputs',
      'openAccessorySettings',
      'currentContent',
      'currentInput',
      'bluetoothAccessories',
      'disconnect',
    };
    final steps = [
      for (final step in tvParitySteps(LgWebOsParityFixture.targets))
        if (names.contains(step.name)) step,
    ];
    final transcript = await ParityRunner(fixture.recorder)
        .run(remote, <ParityStep>[...steps]);
    expectParityGolden('lg_webos_conditional', transcript);
  });
}
