import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';

import 'static_plan_planner.dart';

/// A registry with the stable integrations from `drivers/providers`, as a
/// configured app registers them from its installed packages.
ProviderRegistry integrationProviders(CredentialStore credentials) {
  final engines = ProtocolEngineRegistry([
    SsapEngine(),
    RemoteV2Engine(),
    SamsungChannelEngine(),
    RokuEcpEngine(),
  ]);
  final definitions = [
    for (final folder in const [
      'lg-webos/webos-22-plus',
      'android-tv/remote-v2',
      'samsung-tizen/tizen-supported',
    ])
      IntegrationDefinition.compile(_files(folder), engines),
  ];
  final registry = ProviderRegistry();
  final source = IntegrationProviderSource(
    engines: engines,
    network: const IoDiscoveryNetwork(),
    createController: (device) {
      final definition = definitions.firstWhere(
        (candidate) => candidate.identity.providerId == device.providerId,
      );
      return GenericTvController(
        device,
        planner: StaticPlanPlanner(
          IntegrationPlan(definition, definition.manifest.bootstrapProfile),
        ),
        credentials: credentials,
      );
    },
  );
  final sources = definitions.map(ProviderRuleSource.definition);
  for (final definition in source.definitions(sources)) {
    registry.registerDefinition(definition);
  }
  return registry;
}

Map<String, String> _files(String folder) {
  var directory = Directory.current.absolute;
  while (!Directory('${directory.path}/drivers/providers').existsSync()) {
    directory = directory.parent;
  }
  final source = Directory('${directory.path}/drivers/providers/$folder');
  return {
    for (final file in source.listSync(recursive: true).whereType<File>())
      if (file.path.endsWith('.json'))
        file.path.substring(source.path.length + 1): file.readAsStringSync(),
  };
}
