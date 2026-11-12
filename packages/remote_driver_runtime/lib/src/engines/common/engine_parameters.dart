/// Typed readers for engine mapping parameters. Every engine validates its
/// parameters through these so the rules stay strict and uniform.
final class EngineParameters {
  EngineParameters(this.kind, this._values);

  final String kind;
  final Map<String, Object?> _values;

  void only(Set<String> allowed, {Set<String> required = const {}}) {
    final unknown = _values.keys.where((key) => !allowed.contains(key));
    if (unknown.isNotEmpty) {
      throw FormatException('$kind does not accept "${unknown.first}".');
    }
    final missing = required.where((key) => !_values.containsKey(key));
    if (missing.isNotEmpty) {
      throw FormatException('$kind requires "${missing.first}".');
    }
  }

  String string(String key, RegExp pattern) {
    final value = _values[key];
    if (value is! String || pattern.firstMatch(value)?.end != value.length) {
      throw FormatException('$kind has an invalid "$key".');
    }
    return value;
  }

  String? optionalString(String key, RegExp pattern) =>
      _values[key] == null ? null : string(key, pattern);

  int integer(String key, {required int minimum, required int maximum}) {
    final value = _values[key];
    if (value is! int || value < minimum || value > maximum) {
      throw FormatException('$kind has an out-of-range "$key".');
    }
    return value;
  }

  int? optionalInteger(
    String key, {
    required int minimum,
    required int maximum,
  }) => _values[key] == null
      ? null
      : integer(key, minimum: minimum, maximum: maximum);

  bool flag(String key) {
    final value = _values[key] ?? false;
    if (value is! bool) {
      throw FormatException('$kind has an invalid "$key".');
    }
    return value;
  }

  String choice(String key, Set<String> choices) {
    final value = _values[key];
    if (value is! String || !choices.contains(value)) {
      throw FormatException('$kind has an unsupported "$key".');
    }
    return value;
  }

  Object? raw(String key) => _values[key];
}
