import 'collection_presentation.dart';
import 'remote_item_layout.dart';
import 'remote_layout_visitor.dart';
import 'remote_item_size.dart';

/// Entries of a collection element: apps, inputs or channels.
final class CollectionLayout extends RemoteItemLayout {
  const CollectionLayout(this.presentation, {this.size});

  final CollectionPresentation presentation;

  @override
  final RemoteItemSize? size;

  /// Scrolling rows can scroll either horizontally or vertically.
  bool get scrolls =>
      presentation == CollectionPresentation.strip ||
      presentation == CollectionPresentation.recents;

  @override
  bool supportsPosition(int elementCount) => scrolls;

  @override
  T accept<T>(RemoteLayoutVisitor<T> visitor) => visitor.visitCollection(this);
}
