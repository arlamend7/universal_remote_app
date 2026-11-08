import 'dart:convert';
import 'dart:developer' as developer;

import 'package:universal_remote_app/domains/diagnostics/models/enums/app_log_level.dart';

final class DiagnosticLogger {
  DiagnosticLogger({void Function(String)? sink})
    : _sink =
          sink ?? ((entry) => developer.log(entry, name: 'universal_remote'));
  final void Function(String) _sink;
  bool enabled = false;
  AppLogLevel minimumLevel = AppLogLevel.info;
  void record(
    AppLogLevel level,
    String event, {
    String? errorCode,
    Map<String, Object> fields = const {},
  }) {
    if (!enabled || level.index < minimumLevel.index) {
      return;
    }
    // Event/code vocabulary is application-owned. No free-form exception text.
    _sink(
      jsonEncode({
        ...fields,
        'level': level.name,
        'event': event,
        if (errorCode != null) 'code': errorCode,
      }),
    );
  }
}
