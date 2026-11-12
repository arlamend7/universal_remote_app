import 'dart:convert';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';
import 'package:test/test.dart';

IntegrationManifest _androidTvManifest() {
  var directory = Directory.current.absolute;
  while (!Directory('${directory.path}/drivers/providers').existsSync()) {
    directory = directory.parent;
  }
  return IntegrationManifest.fromJson(
    jsonDecode(
      File(
        '${directory.path}/drivers/providers/android-tv/remote-v2/'
        'manifest.json',
      ).readAsStringSync(),
    ) as Map<String, Object?>,
  );
}

DeviceSoftwareInformation _reported(String? vendor, String? model) =>
    DeviceSoftwareInformation(
      source: DeviceInformationSource.authenticatedSession,
      manufacturer: vendor,
      model: model,
      operatingSystem: 'Android TV',
      protocolVersion: 'Remote v2',
    );

void main() {
  final androidTv = IntegrationCandidate.manifest(_androidTvManifest());

  test('every Remote v2 TV bootstraps on the one Android TV integration', () {
    final plan = IntegrationResolver.bootstrap('android.tv', [androidTv])!;
    expect(plan.identity.integrationId, 'android.tv.remote-v2');
    expect(plan.profile.id, 'bootstrap');
    expect(androidTv.compatibility.isUnrestricted, isTrue);
  });

  test('vendor, model and unknown OS or firmware never reject or re-route', () {
    final bootstrap = IntegrationResolver.bootstrap('android.tv', [androidTv])!;
    for (final software in [
      null,
      _reported(null, null),
      _reported('TCL', 'Smart TV Pro'),
      _reported('TCL', null),
      _reported('Google', 'Chromecast'),
      _reported('Sony', 'BRAVIA 4K VH2'),
    ]) {
      final plan = IntegrationResolver.identified(bootstrap, [
        androidTv,
      ], software);
      expect(plan.identity.integrationId, 'android.tv.remote-v2');
      expect(plan.profile.id, 'bootstrap');
    }
  });

  test('a model profile can refine the integration once evidence exists', () {
    // Illustrative only: no TCL profile ships, because no verified TCL
    // behaviour differs from other Remote v2 televisions.
    final withProfile = IntegrationCandidate(
      identity: androidTv.identity,
      compatibility: androidTv.compatibility,
      profiles: [
        ...androidTv.profiles,
        CompatibilityProfile.fromJson({
          'id': 'verified-model',
          'stage': 'identified',
          'compatibility': {
            'models': ['Verified Model'],
          },
        }),
      ],
    );
    final bootstrap = IntegrationResolver.bootstrap('android.tv', [
      withProfile,
    ])!;
    IntegrationSelection resolve(DeviceSoftwareInformation? software) =>
        IntegrationResolver.identified(bootstrap, [withProfile], software);
    expect(
      resolve(_reported('TCL', 'Verified Model')).profile.id,
      'verified-model',
    );
    expect(resolve(_reported('TCL', 'Other Model')).profile.id, 'bootstrap');
    expect(resolve(_reported('TCL', null)).profile.id, 'bootstrap');
    expect(resolve(null).profile.id, 'bootstrap');
  });
}
