import 'dart:convert';
import 'dart:io';

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
    final files = _files(Directory(arguments.single));
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

Map<String, String> _files(Directory directory) {
  final root = directory.absolute.path;
  final files = <String, String>{};
  for (final entry in directory.listSync(recursive: true, followLinks: false)) {
    if (entry is Link) {
      throw const FormatException('Integration folders cannot contain links.');
    }
    if (entry is! File || !entry.path.endsWith('.json')) {
      continue;
    }
    final name = entry.absolute.path.substring(root.length + 1);
    if (files.length >= 64 || entry.lengthSync() > 256 * 1024) {
      throw const FormatException('Integration folder exceeds its limits.');
    }
    files[name] = entry.readAsStringSync();
  }
  return files;
}
