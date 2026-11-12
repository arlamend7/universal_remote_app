/// Result of comparing reported device software with a declared range.
enum VersionMatch {
  matches,
  mismatches,

  /// The device did not report a comparable value; never assume support.
  unknown,
}
