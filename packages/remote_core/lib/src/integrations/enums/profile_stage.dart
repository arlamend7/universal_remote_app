/// When a compatibility profile may be selected for a connection.
enum ProfileStage {
  /// Usable before authentication, from discovery evidence only.
  bootstrap('bootstrap'),

  /// Requires software identified by an authenticated session.
  identified('identified');

  const ProfileStage(this.id);
  final String id;

  static ProfileStage parse(Object? value) {
    final stage = values.where((candidate) => candidate.id == value);
    if (stage.isEmpty) {
      throw const FormatException('Unknown compatibility profile stage.');
    }
    return stage.single;
  }
}
