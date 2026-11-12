/// Which evidence a compatibility selection was based on.
enum SelectionStage {
  /// Discovery evidence only, before authentication.
  bootstrap,

  /// Software reported by an authenticated session.
  identified,
}
