import 'dart:convert';

import 'package:remote_core/remote_core.dart';

final class DriverStep {
  const DriverStep._(this.operation, this.message);

  factory DriverStep.fromJson(Object? value) {
    if (value is! Map<String, Object?> || value['operation'] is! String) {
      throw const FormatException('Driver steps require an operation ID.');
    }
    final operation = DriverOperation.parse(value['operation'] as String);
    final sends = switch (operation) {
      DriverOperation.webSocketConnect ||
      DriverOperation.webSocketDisconnect ||
      DriverOperation.webSocketAwaitJson => false,
      _ => true,
    };
    if (value.length != (sends ? 2 : 1)) {
      throw const FormatException('Unexpected driver step fields.');
    }
    final payload = value['payload'];
    if (sends && payload is! Map<String, Object?>) {
      throw const FormatException('A send step requires a JSON object.');
    }
    if (_tooDeep(payload, 0)) {
      throw const FormatException('Driver payload nesting exceeds the limit.');
    }
    return DriverStep._(operation, sends ? jsonEncode(payload) : null);
  }

  final DriverOperation operation;
  final String? message;

  String render(Map<String, Object> arguments) {
    final template = message!;
    final value = _bind(jsonDecode(template), arguments);
    final rendered = jsonEncode(value);
    if (utf8.encode(rendered).length > 16384) {
      throw const FormatException(
        'Driver command payload exceeds the size limit.',
      );
    }
    return rendered;
  }

  static Object? _bind(Object? value, Map<String, Object> arguments) {
    if (value is Map<String, Object?> && value.containsKey(r'$argument')) {
      final name = value[r'$argument'];
      if (value.length != 1 ||
          name is! String ||
          !arguments.containsKey(name)) {
        throw const FormatException(
          'Missing or invalid driver command argument.',
        );
      }
      final argument = arguments[name];
      if (argument is String ||
          argument is bool ||
          (argument is num && argument.isFinite)) {
        return argument;
      }
      throw const FormatException(
        'Driver command arguments must be scalar values.',
      );
    }
    return switch (value) {
      Map<String, Object?> map => map.map(
        (key, child) => MapEntry(key, _bind(child, arguments)),
      ),
      List<Object?> list =>
        list.map((child) => _bind(child, arguments)).toList(),
      _ => value,
    };
  }

  static bool _tooDeep(Object? value, int depth) {
    if (depth > 16) {
      return true;
    }
    return switch (value) {
      Map<String, Object?> map => map.values.any(
        (child) => _tooDeep(child, depth + 1),
      ),
      List<Object?> list => list.any((child) => _tooDeep(child, depth + 1)),
      _ => false,
    };
  }
}
