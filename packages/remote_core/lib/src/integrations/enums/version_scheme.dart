/// How a device version string is compared with a compatibility range.
enum VersionScheme {
  /// Dot-separated numeric components; missing components count as zero.
  dottedNumeric('dotted-numeric'),

  /// Only `=` comparisons against the exact reported string are allowed.
  exact('exact');

  const VersionScheme(this.id);
  final String id;

  static VersionScheme parse(Object? value) {
    final scheme = values.where((candidate) => candidate.id == value);
    if (scheme.isEmpty) {
      throw const FormatException('Unknown version comparison scheme.');
    }
    return scheme.single;
  }
}
