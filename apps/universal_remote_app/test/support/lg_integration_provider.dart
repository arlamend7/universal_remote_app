import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';
import 'package:remote_network/remote_network.dart';

import 'static_plan_planner.dart';

/// The LG webOS 22+ integration from `drivers/providers`, as the app would
/// register it, with an injectable transport.
ProviderDefinition<RemoteBase> lgIntegrationProvider({
  required CredentialStore credentials,
  TransportConnector? connector,
  RemoteBase Function(RemoteDevice device)? createController,
}) {
  final engines = ProtocolEngineRegistry([SsapEngine(connector: connector)]);
  final definition = IntegrationDefinition.compile(
    _files('lg-webos/webos-22-plus'),
    engines,
  );
  final planner = StaticPlanPlanner(
    IntegrationPlan(definition, definition.manifest.bootstrapProfile),
  );
  return IntegrationProviderSource(
    engines: engines,
    credentials: credentials,
    network: const IoDiscoveryNetwork(),
    createController:
        createController ??
        (device) => GenericTvController(
          device,
          planner: planner,
          credentials: credentials,
        ),
  ).definitions([ProviderRuleSource.definition(definition)]).single;
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
