import 'dart:convert';
import 'dart:io';

/// Expands explicitly shared source files before validating or packing a driver.
Map<String, String> readDriverSourceFiles(Directory directory) {
  final root = directory.absolute.path;
  final files = <String, String>{};
  for (final entry in directory.listSync(recursive: true, followLinks: false)) {
    if (entry is Link) {
      throw const FormatException('Integration folders cannot contain links.');
    }
    if (entry is File && entry.path.endsWith('.json')) {
      final name = entry.absolute.path.substring(root.length + 1);
      _addSource(files, name, entry);
    }
  }
  final shared = files.remove('shared-files.json');
  if (shared == null) {
    return files;
  }
  _addShared(files, directory.parent, jsonDecode(shared));
  return files;
}

void _addShared(
  Map<String, String> files,
  Directory provider,
  Object? requested,
) {
  if (requested is! List<Object?> ||
      requested.isEmpty ||
      requested.toSet().length != requested.length ||
      !requested.every(_shareable.contains)) {
    throw const FormatException('Invalid shared driver files.');
  }
  final directory = '${provider.path}/_shared';
  if (FileSystemEntity.typeSync(directory, followLinks: false) !=
      FileSystemEntityType.directory) {
    throw const FormatException(
      'Shared driver source directory is unavailable.',
    );
  }
  for (final name in requested.cast<String>()) {
    final file = File('$directory/$name');
    if (files.containsKey(name) ||
        FileSystemEntity.typeSync(file.path, followLinks: false) !=
            FileSystemEntityType.file) {
      throw const FormatException(
        'Shared driver files must be unique regular files.',
      );
    }
    _addSource(files, name, file);
  }
}

void _addSource(Map<String, String> files, String name, File entry) {
  if (files.length >= 64 || entry.lengthSync() > 256 * 1024) {
    throw const FormatException('Integration folder exceeds its limits.');
  }
  files[name] = entry.readAsStringSync();
}

const _shareable = {
  'capabilities.json',
  'connection.json',
  'device.json',
  'discovery.json',
  'mappings.json',
};
