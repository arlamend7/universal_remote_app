import 'dart:convert';
import 'dart:io';

import 'package:remote_driver_runtime/authoring.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';

/// Validates a schema-2 integration folder against every compiled engine and
/// prints its manifest and files for the packaging tools.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    stderr.writeln('Usage: validate_driver DIRECTORY');
    exitCode = 64;
    return;
  }
  try {
    final files = readDriverSourceFiles(Directory(arguments.single));
    final definition = IntegrationDefinition.compile(
      files,
      ProtocolEngineRegistry([
        SsapEngine(),
        RemoteV2Engine(),
        SamsungChannelEngine(),
        RokuEcpEngine(),
        JsonWebSocketEngine(),
      ]),
    );
    final discovery = definition.document('discovery.json');
    if (discovery != null) {
      DiscoveryRules.fromJson(discovery);
    }
    DeviceRules.fromJson(definition.document('device.json') ?? const {});
    stdout.writeln(
      jsonEncode({'manifest': definition.manifest.toJson(), 'files': files}),
    );
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 65;
  } on FileSystemException {
    stderr.writeln('Unable to read the integration directory.');
    exitCode = 66;
  }
}
