import 'dart:convert';

/// A bounded JSON payload whose leaves may reference call arguments as
/// `{"$argument": "name"}`; `"optional": true` omits the key when the
/// argument is null. Templates are data: nothing in them executes.
final class PayloadTemplate {
  PayloadTemplate._(this._template);

  factory PayloadTemplate.parse(Object? value, Set<String> arguments) {
    final template = value ?? const <String, Object?>{};
    if (template is! Map<String, Object?> ||
        utf8.encode(jsonEncode(template)).length > 4096) {
      throw const FormatException('Invalid payload template.');
    }
    _check(template, arguments, 0);
    return PayloadTemplate._(template);
  }

  /// Argument names an engine call may receive from the controller.
  static const arguments = {
    'volume',
    'muted',
    'text',
    'target',
    'id',
    'contentId',
    'dx',
    'dy',
  };

  final Map<String, Object?> _template;

  Map<String, Object?> get template => _template;

  Map<String, Object?> render(Map<String, Object?> values) =>
      _render(_template, values)! as Map<String, Object?>;

  static void _check(Object? value, Set<String> arguments, int depth) {
    if (depth > 8) {
      throw const FormatException('Payload template is too deep.');
    }
    if (value == null || value is bool || value is num || value is String) {
      return;
    }
    if (value is List<Object?>) {
      _checkList(value, arguments, depth);
      return;
    }
    if (value is! Map<String, Object?>) {
      throw const FormatException('Invalid payload template value.');
    }
    if (value.containsKey(r'$argument')) {
      _checkArgument(value, arguments);
      return;
    }
    for (final child in value.values) {
      _check(child, arguments, depth + 1);
    }
  }

  static void _checkList(
    List<Object?> value,
    Set<String> arguments,
    int depth,
  ) {
    if (value.length > 64) {
      throw const FormatException('Payload template list is too long.');
    }
    for (final child in value) {
      _check(child, arguments, depth + 1);
    }
  }

  static void _checkArgument(
    Map<String, Object?> value,
    Set<String> arguments,
  ) {
    final name = value[r'$argument'];
    final optional = value['optional'];
    final keys = value.keys.toSet()..removeAll({r'$argument', 'optional'});
    if (keys.isNotEmpty ||
        (optional != null && optional is! bool) ||
        name is! String ||
        !arguments.contains(name)) {
      throw const FormatException('Unknown payload argument.');
    }
  }

  static Object? _render(Object? value, Map<String, Object?> values) {
    if (value is List<Object?>) {
      return [for (final child in value) _render(child, values)];
    }
    if (value is! Map<String, Object?>) {
      return value;
    }
    if (value[r'$argument'] case final String name) {
      if (!values.containsKey(name)) {
        throw ArgumentError('Missing argument "$name".');
      }
      return values[name];
    }
    return {
      for (final entry in value.entries)
        if (!_omitted(entry.value, values))
          entry.key: _render(entry.value, values),
    };
  }

  static bool _omitted(Object? value, Map<String, Object?> values) =>
      value is Map<String, Object?> &&
      value['optional'] == true &&
      values[value[r'$argument']] == null;
}
