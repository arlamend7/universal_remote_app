import 'dart:convert';
import 'dart:io';

/// Reads a shared fixture from `drivers/fixtures/v2`, the files Python
/// tooling validates too, so Dart and Python decode the same documents.
Map<String, Object?> driverFixture(String name) {
  var directory = Directory.current.absolute;
  while (!File('${directory.path}/drivers/fixtures/v2/$name').existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('drivers/fixtures/v2/$name was not found.');
    }
    directory = parent;
  }
  final file = File('${directory.path}/drivers/fixtures/v2/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

/// The repository's `drivers/schema/v2` file with [name].
Map<String, Object?> driverSchema(String name) {
  final fixture = driverFixturePath('manifest.json');
  final root = File(fixture).parent.parent.parent.path;
  final file = File('$root/schema/v2/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

String driverFixturePath(String name) {
  var directory = Directory.current.absolute;
  while (!File('${directory.path}/drivers/fixtures/v2/$name').existsSync()) {
    directory = directory.parent;
  }
  return '${directory.path}/drivers/fixtures/v2/$name';
}
