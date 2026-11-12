import 'dart:io';

/// The JSON files of `drivers/providers/<folder>`, as a package would hold.
Map<String, String> integrationFiles(String folder) {
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
