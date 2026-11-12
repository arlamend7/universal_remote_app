import 'dart:convert';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';
import 'package:remote_driver_runtime/devices.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';
import 'package:test/test.dart';

IntegrationCandidate _lg(String id, String range, int priority) =>
    IntegrationCandidate(
      identity: IntegrationIdentity(integrationId: id, providerId: 'lg.webos'),
      compatibility: IntegrationCompatibility.fromJson({'osVersion': range}),
      priority: priority,
      profiles: [
        CompatibilityProfile.fromJson({
          'id': 'bootstrap',
          'stage': 'bootstrap',
        }),
        CompatibilityProfile.fromJson({
          'id': 'webos-23-plus',
          'stage': 'identified',
          'compatibility': {'osVersion': '>=8'},
        }),
      ],
    );

Map<String, Object?> _source(String path) {
  var directory = Directory.current.absolute;
  while (!Directory('${directory.path}/drivers/providers').existsSync()) {
    directory = directory.parent;
  }
  return jsonDecode(
    File('${directory.path}/drivers/providers/$path').readAsStringSync(),
  ) as Map<String, Object?>;
}

void main() {
  final modern = _lg('lg.webos.22-plus', '>=7', 10);
  final legacy = _lg('lg.webos.legacy', '<7', 0);
  final candidates = [legacy, modern];

  test('bootstrap picks the highest priority, or the saved assignment', () {
    final first = IntegrationResolver.bootstrap('lg.webos', candidates)!;
    expect(first.identity.integrationId, 'lg.webos.22-plus');
    expect(first.profile.id, 'bootstrap');
    expect(first.stage, SelectionStage.bootstrap);
    final saved = IntegrationResolver.bootstrap(
      'lg.webos',
      candidates,
      assigned: 'lg.webos.legacy',
    )!;
    expect(saved.identity.integrationId, 'lg.webos.legacy');
    expect(IntegrationResolver.bootstrap('roku.ecp', candidates), isNull);
  });

  test('identified software refines the integration and profile', () {
    final first = IntegrationResolver.bootstrap('lg.webos', candidates)!;
    final webos5 = IntegrationResolver.identified(
      first,
      candidates,
      const DeviceSoftwareEvidence(os: '5.0'),
    );
    expect(webos5.identity.integrationId, 'lg.webos.legacy');
    final webos8 = IntegrationResolver.identified(
      first,
      candidates,
      const DeviceSoftwareEvidence(os: '8.1'),
    );
    expect(webos8.identity.integrationId, 'lg.webos.22-plus');
    expect(webos8.profile.id, 'webos-23-plus');
    final unknown = IntegrationResolver.identified(
      first,
      candidates,
      const DeviceSoftwareEvidence(),
    );
    expect(unknown.identity.integrationId, 'lg.webos.22-plus');
    expect(unknown.profile.id, 'bootstrap');
  });

  test('development integrations need explicit permission', () {
    final roku = IntegrationCandidate(
      identity: IntegrationIdentity(
        integrationId: 'roku.ecp.supported',
        providerId: 'roku.ecp',
      ),
      compatibility: IntegrationCompatibility(),
      profiles: [
        CompatibilityProfile.fromJson({
          'id': 'bootstrap',
          'stage': 'bootstrap',
        }),
      ],
      development: true,
    );
    expect(IntegrationResolver.bootstrap('roku.ecp', [roku]), isNull);
    expect(
      IntegrationResolver.bootstrap('roku.ecp', [roku], allowDevelopment: true),
      isNotNull,
    );
  });

  test('provider definitions are built from integration data', () {
    ProviderRuleSource source(
      String providerId,
      String integration,
      String folder,
      String engine, {
      bool development = false,
    }) => ProviderRuleSource(
      identity: IntegrationIdentity(
        integrationId: integration,
        providerId: providerId,
      ),
      engine: engine,
      development: development,
      discovery: _source('$folder/discovery.json'),
      device: _source('$folder/device.json'),
    );
    final sources = [
      source('lg.webos', 'lg.webos.22-plus', 'lg-webos/webos-22-plus', 'ssap'),
      source(
        'android.tv',
        'android.tv.remote-v2',
        'android-tv/remote-v2',
        'android-remote-v2',
      ),
      source(
        'samsung.tizen',
        'samsung.tizen.supported',
        'samsung-tizen/tizen-supported',
        'samsung-channel',
      ),
      source(
        'roku.ecp',
        'roku.ecp.supported',
        'roku-ecp/roku-supported',
        'roku-ecp',
        development: true,
      ),
    ];
    IntegrationProviderSource build({required bool development}) =>
        IntegrationProviderSource(
          engines: ProtocolEngineRegistry([
            SsapEngine(),
            RemoteV2Engine(),
            SamsungChannelEngine(),
            RokuEcpEngine(),
          ]),
          network: const IoDiscoveryNetwork(),
          createController: (_) => throw UnimplementedError(),
          allowDevelopment: development,
        );
    final release = build(development: false).definitions(sources);
    expect(release.map((definition) => definition.id), [
      'lg.webos',
      'android.tv',
      'samsung.tizen',
    ]);
    final lg = release.first;
    expect(lg.identifier.label, 'LG webOS');
    expect(lg.manualSetup?.manualSetupLabel, 'LG webOS');
    expect(lg.connection?.category, DeviceCategory.television);
    final development = build(development: true).definitions(sources);
    final roku = development.last;
    expect(roku.id, 'roku.ecp');
    final device = RemoteDevice(
      id: 'roku.ecp:x',
      name: 'Roku',
      providerId: 'roku.ecp',
      endpoints: [Uri.parse('http://192.168.1.30:8060')],
      capabilities: {RemoteCapability.power},
    );
    expect(roku.wake?.canWakeDevice(device), isTrue);
    expect(roku.connection, isNull);
  });
}
