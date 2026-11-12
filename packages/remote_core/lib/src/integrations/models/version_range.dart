import '../enums/version_match.dart';
import '../enums/version_scheme.dart';

/// A conjunction of comparisons such as `>=7 <9`, or `=webOS 7.0` for exact
/// strings. Physical-device ranges only; integration packages are not versioned.
final class VersionRange {
  VersionRange._(this.expression, this._terms);

  factory VersionRange.parse(String expression, VersionScheme scheme) {
    final parts = expression.trim().split(RegExp(r'\s+'));
    if (expression.length > 128 || parts.isEmpty || parts.length > 4) {
      throw const FormatException('Invalid device version range.');
    }
    final terms = scheme == VersionScheme.exact
        ? [_exactTerm(expression)]
        : parts.map(_numericTerm).toList();
    return VersionRange._(expression, List.unmodifiable(terms));
  }

  static final _numeric = RegExp(r'^(>=|<=|>|<|=)(\d+(?:\.\d+){0,5})$');
  static final _prefix = RegExp(r'^\d+(?:\.\d+){0,5}');

  final String expression;
  final List<(String, String)> _terms;

  VersionMatch match(String? reported, VersionScheme scheme) {
    final value = reported?.trim();
    if (value == null || value.isEmpty) {
      return VersionMatch.unknown;
    }
    if (scheme == VersionScheme.exact) {
      return value == _terms.single.$2
          ? VersionMatch.matches
          : VersionMatch.mismatches;
    }
    final comparable = _prefix.firstMatch(value)?.group(0);
    if (comparable == null) {
      return VersionMatch.unknown;
    }
    return _terms.every((term) => _satisfies(comparable, term))
        ? VersionMatch.matches
        : VersionMatch.mismatches;
  }

  static (String, String) _numericTerm(String term) {
    final match = _numeric.firstMatch(term);
    if (match == null) {
      throw const FormatException('Invalid device version comparison.');
    }
    return (match[1]!, match[2]!);
  }

  static (String, String) _exactTerm(String expression) {
    if (!expression.startsWith('=') || expression.length < 2) {
      throw const FormatException('Exact version ranges must use =value.');
    }
    return ('=', expression.substring(1));
  }

  static bool _satisfies(String value, (String, String) term) {
    final order = compareDottedVersions(value, term.$2);
    return switch (term.$1) {
      '>=' => order >= 0,
      '>' => order > 0,
      '<=' => order <= 0,
      '<' => order < 0,
      _ => order == 0,
    };
  }

  @override
  String toString() => expression;
}

/// Compares numeric components; `7` equals `7.0` and `04` equals `4`.
int compareDottedVersions(String left, String right) {
  final a = left.split('.').map(int.parse).toList();
  final b = right.split('.').map(int.parse).toList();
  final length = a.length > b.length ? a.length : b.length;
  for (var index = 0; index < length; index++) {
    final difference =
        (index < a.length ? a[index] : 0) - (index < b.length ? b[index] : 0);
    if (difference != 0) {
      return difference.sign;
    }
  }
  return 0;
}
