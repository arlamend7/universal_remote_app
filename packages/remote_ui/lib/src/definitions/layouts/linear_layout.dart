import 'remote_item_layout.dart';
import 'remote_item_size.dart';
import 'remote_layout_visitor.dart';

/// The item's elements in one row or column, in registration order. Each
/// element takes space in proportion to its slots.
final class LinearLayout extends RemoteItemLayout {
  const LinearLayout({this.size});

  @override
  final RemoteItemSize? size;

  @override
  T accept<T>(RemoteLayoutVisitor<T> visitor) => visitor.visitLinear(this);
}
