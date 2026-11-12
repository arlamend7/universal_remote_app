import 'dart:convert';
import 'dart:io';

import 'package:remote_driver_runtime/authoring.dart';

/// Reads `drivers/providers/<integration>/<file>` from the repository.
Map<String, Object?> driverSource(String integration, String file) {
  var directory = Directory.current.absolute;
  while (!Directory('${directory.path}/drivers/providers').existsSync()) {
    directory = directory.parent;
  }
  final source = Directory('${directory.path}/drivers/providers/$integration');
  return jsonDecode(readDriverSourceFiles(source)[file]!)
      as Map<String, Object?>;
}
