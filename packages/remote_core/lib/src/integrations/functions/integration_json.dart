/// Strict readers shared by integration metadata decoders.
abstract final class IntegrationJson {
  static final _identifier = RegExp(r'^[a-z][a-z0-9._-]{0,79}$');

  static Map<String, Object?> object(Object? value, String field) {
    if (value is! Map<String, Object?>) {
      throw FormatException('Invalid integration object: $field.');
    }
    return value;
  }

  static void keys(
    Map<String, Object?> json,
    Set<String> allowed, {
    Set<String> required = const {},
  }) {
    final unknown = json.keys.where((key) => !allowed.contains(key));
    if (unknown.isNotEmpty) {
      throw FormatException('Unknown integration field: ${unknown.first}.');
    }
    final missing = required.where((key) => !json.containsKey(key));
    if (missing.isNotEmpty) {
      throw FormatException('Missing integration field: ${missing.first}.');
    }
  }

  static String label(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || !isLabel(value)) {
      throw FormatException('Invalid integration field: $key.');
    }
    return value;
  }

  static String? optionalLabel(Map<String, Object?> json, String key) =>
      json[key] == null ? null : label(json, key);

  static String identifier(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || !isIdentifier(value)) {
      throw FormatException('Invalid integration identifier: $key.');
    }
    return value;
  }

  static int integer(
    Map<String, Object?> json,
    String key, {
    int minimum = 0,
    int maximum = 999999999,
  }) {
    final value = json[key];
    if (value is! int || value < minimum || value > maximum) {
      throw FormatException('Invalid integration number: $key.');
    }
    return value;
  }

  static List<Object?> list(
    Map<String, Object?> json,
    String key, {
    int maximum = 256,
  }) {
    final value = json[key] ?? const <Object?>[];
    if (value is! List<Object?> || value.length > maximum) {
      throw FormatException('Invalid integration list: $key.');
    }
    return value;
  }

  static List<String> labels(Map<String, Object?> json, String key) => [
    for (final value in list(json, key)) _labelValue(value, key),
  ];

  static DateTime timestamp(Object? value, String field) {
    final parsed = value is String && value.endsWith('Z')
        ? DateTime.tryParse(value)
        : null;
    if (parsed == null || !parsed.isUtc) {
      throw FormatException('Invalid UTC timestamp: $field.');
    }
    return parsed;
  }

  /// Second-precision UTC form used by catalogs and manifests.
  static String formatTimestamp(DateTime value) {
    final utc = value.toUtc();
    final seconds = DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
    );
    return '${seconds.toIso8601String().split('.').first}Z';
  }

  static bool isLabel(String value) =>
      value.isNotEmpty && value.length <= 128 && value.trim() == value;

  static bool isIdentifier(String value) =>
      _identifier.firstMatch(value)?.end == value.length;

  static String _labelValue(Object? value, String key) {
    if (value is! String || !isLabel(value)) {
      throw FormatException('Invalid integration list entry: $key.');
    }
    return value;
  }
}
