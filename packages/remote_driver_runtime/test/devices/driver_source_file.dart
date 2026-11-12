import 'dart:convert';
import 'dart:io';

/// Reads `drivers/providers/<integration>/<file>` from the repository.
Map<String, Object?> driverSource(String integration, String file) {
  var directory = Directory.current.absolute;
  while (!Directory('${directory.path}/drivers/providers').existsSync()) {
    directory = directory.parent;
  }
  final path = '${directory.path}/drivers/providers/$integration/$file';
  return jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
}
