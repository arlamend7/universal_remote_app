import 'dart:convert';
import 'dart:io';

import 'driver_bundle.dart';

/// Used by explicitly enabled local development and authoring tools.
final class LocalDriverSource {
  const LocalDriverSource({required this.enabled});

  final bool enabled;

  Future<DriverBundle> load(Directory directory) async =>
      DriverBundle.parse(await files(directory));

  Future<Map<String, String>> files(Directory directory) async {
    if (!enabled) {
      throw StateError('Local driver loading is disabled.');
    }
    final root = directory.absolute.path;
    if (await FileSystemEntity.type(root, followLinks: false) !=
        FileSystemEntityType.directory) {
      throw const FormatException('Expected a regular driver directory.');
    }
    final prefix = root.endsWith(Platform.pathSeparator)
        ? root
        : '$root${Platform.pathSeparator}';
    final files = <String, String>{};
    var entries = 0;
    await for (final entry in Directory(
      root,
    ).list(recursive: true, followLinks: false)) {
      final relative = entry.path
          .substring(prefix.length)
          .replaceAll(Platform.pathSeparator, '/');
      if (++entries > DriverBundle.maximumFiles + 3) {
        throw const FormatException('Too many driver directory entries.');
      }
      if (entry is Directory && _folders.contains(relative)) {
        continue;
      }
      if (entry is! File || !_validPath(relative)) {
        throw const FormatException(
          'Unexpected entry in the driver directory.',
        );
      }
      files[relative] = await _read(entry);
    }
    return Map.unmodifiable(files);
  }

  static Future<String> _read(File entry) async {
    final handle = await entry.open();
    try {
      final bytes = await handle.read(DriverBundle.maximumFileBytes + 1);
      if (bytes.length > DriverBundle.maximumFileBytes) {
        throw const FormatException('Driver file exceeds its size limit.');
      }
      return utf8.decode(bytes);
    } finally {
      await handle.close();
    }
  }

  static bool _validPath(String path) =>
      _filePath.firstMatch(path)?.end == path.length;

  static const _folders = {'commands', 'workflows', 'compatibility'};
  static final _filePath = RegExp(
    r'^(?:manifest|discovery|capabilities|(?:commands|workflows)/[a-z][a-z0-9_-]{0,63})\.json$',
  );
}
