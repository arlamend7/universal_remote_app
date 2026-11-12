import 'dart:io';

import 'package:remote_core/remote_core.dart';

import 'atomic_json_file.dart';

/// Persists when the next automatic update check is due (`updates.json`).
final class UpdateSchedule {
  UpdateSchedule(Directory root)
    : _file = AtomicJsonFile(File('${root.path}/updates.json'));

  final AtomicJsonFile _file;

  Future<DateTime?> nextCheck() async {
    final json = await _file.read();
    final value = json?['nextUpdate'];
    return value == null
        ? null
        : IntegrationJson.timestamp(value, 'nextUpdate');
  }

  Future<void> schedule(DateTime next) =>
      _file.write({'nextUpdate': IntegrationJson.formatTimestamp(next)});
}
