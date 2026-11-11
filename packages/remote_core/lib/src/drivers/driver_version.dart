/// Stable package or runtime version. Device firmware uses a separate format.
final class DriverVersion implements Comparable<DriverVersion> {
  const DriverVersion._(this.major, this.minor, this.patch);

  factory DriverVersion.parse(String value) {
    final match = _format.firstMatch(value);
    if (match == null || match.end != value.length) {
      throw const FormatException(
        'Expected a stable major.minor.patch version.',
      );
    }
    return DriverVersion._(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  static final _format = RegExp(
    r'^(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})$',
  );

  final int major, minor, patch;

  @override
  int compareTo(DriverVersion other) {
    final majorOrder = major.compareTo(other.major);
    if (majorOrder != 0) {
      return majorOrder;
    }
    final minorOrder = minor.compareTo(other.minor);
    return minorOrder == 0 ? patch.compareTo(other.patch) : minorOrder;
  }

  @override
  bool operator ==(Object other) =>
      other is DriverVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
