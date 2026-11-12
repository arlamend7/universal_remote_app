import 'dart:typed_data';

/// A signed catalog envelope and package objects shipped with the app, so a
/// fresh install can control TVs before it ever reaches the repository.
final class SeedBundle {
  SeedBundle(this.envelope, Map<String, Uint8List> objects)
    : objects = Map.unmodifiable(objects);

  final String envelope;

  /// Package bytes keyed by their SHA-256.
  final Map<String, Uint8List> objects;
}
