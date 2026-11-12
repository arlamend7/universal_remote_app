import 'dart:io';

import 'package:remote_driver_runtime/authoring.dart';

/// The JSON files of `drivers/providers/<folder>`, as a package would hold.
Map<String, String> integrationFiles(String folder) {
  var directory = Directory.current.absolute;
  while (!Directory('${directory.path}/drivers/providers').existsSync()) {
    directory = directory.parent;
  }
  final source = Directory('${directory.path}/drivers/providers/$folder');
  return readDriverSourceFiles(source);
}
