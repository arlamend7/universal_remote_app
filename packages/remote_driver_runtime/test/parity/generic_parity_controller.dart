import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/integrations.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';

import '../controller/static_integration_planner.dart';
import 'support/integration_files.dart';
import 'support/parity_recorder.dart';

/// A generic controller running one `drivers/providers` integration.
GenericTvController genericParityController(
  String folder,
  ProtocolEngine engine,
  RemoteDevice device,
  CredentialStore credentials,
  ParityRecorder recorder,
) {
  final definition = IntegrationDefinition.compile(
    integrationFiles(folder),
    ProtocolEngineRegistry([engine]),
  );
  return GenericTvController(
    device,
    planner: StaticIntegrationPlanner(
      IntegrationPlan(definition, definition.manifest.bootstrapProfile),
    ),
    credentials: credentials,
    wakeSender: (mac, broadcast) async => recorder.add({'wake': 'wake-on-lan'}),
  );
}
