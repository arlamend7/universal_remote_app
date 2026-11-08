import 'dart:convert';

List<(String, String)> widgetTargets(String? raw) {
  if (raw == null) {
    return [];
  }
  try {
    final value = jsonDecode(raw);
    if (value is! List) {
      return [];
    }
    return value
        .whereType<Map<String, dynamic>>()
        .where((item) => item['id'] is String && item['name'] is String)
        .take(32)
        .map((item) => (item['id'] as String, item['name'] as String))
        .toList();
  } catch (_) {
    return [];
  }
}

String encodeWidgetTargets(List<(String, String)> targets) => jsonEncode(
  targets.map((item) => {'id': item.$1, 'name': item.$2}).toList(),
);
