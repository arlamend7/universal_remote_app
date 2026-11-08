/// How a collection layout presents its entries.
enum CollectionPresentation {
  /// One button that opens a picker of every entry.
  chooser,

  /// The first pinned entry as a labelled button.
  shortcut,

  /// The first pinned entry as an icon-only button.
  icon,

  /// Pinned entries in a grid as wide as the item.
  grid,

  /// Pinned entries in a horizontal scrolling row.
  strip,

  /// Recently launched entries in a horizontal scrolling row.
  recents;

  /// Shows one pinned entry, so choosing a new one replaces the old.
  bool get isSingle => this == shortcut || this == icon;

  /// Whether the user picks the entries in the editor (a chooser lists every
  /// entry itself, and recents fill themselves).
  bool get choosesTargets => this != chooser && this != recents;
}
