import 'dart:convert';
import 'dart:io';

/// A bounded JSON document replaced atomically by rename.
final class AtomicJsonFile {
  const AtomicJsonFile(this.file, {this.maximumBytes = 4 * 1024 * 1024});

  final File file;
  final int maximumBytes;

  Future<Map<String, Object?>?> read() async {
    if (!await file.exists()) {
      return null;
    }
    final handle = await file.open();
    try {
      final bytes = await handle.read(maximumBytes + 1);
      if (bytes.length > maximumBytes) {
        throw const FormatException('Driver storage entry is too large.');
      }
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map<String, Object?>) {
        throw const FormatException('Invalid driver storage entry.');
      }
      return json;
    } finally {
      await handle.close();
    }
  }

  Future<void> write(Map<String, Object?> json) async {
    final bytes = utf8.encode(jsonEncode(json));
    if (bytes.length > maximumBytes) {
      throw const FormatException('Driver storage entry is too large.');
    }
    final directory = file.parent;
    await directory.create(recursive: true);
    final stage = await directory.createTemp('staging-');
    try {
      final pending = File('${stage.path}/content.json');
      await pending.writeAsBytes(bytes, flush: true);
      await pending.rename(file.path);
    } finally {
      await stage.delete(recursive: true);
    }
  }

  Future<void> delete() async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
