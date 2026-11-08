import 'remote_item_layout.dart';
import 'remote_item_size.dart';
import 'remote_layout_visitor.dart';

/// A numeric input turned by dragging around a circle, with its reading at
/// the centre.
final class DialLayout extends RemoteItemLayout {
  const DialLayout({required this.size});

  @override
  final RemoteItemSize size;

  @override
  T accept<T>(RemoteLayoutVisitor<T> visitor) => visitor.visitDial(this);
}
