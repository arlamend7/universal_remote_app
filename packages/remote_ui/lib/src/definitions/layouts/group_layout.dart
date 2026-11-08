import 'remote_item_layout.dart';
import 'remote_layout_visitor.dart';
import 'remote_item_size.dart';

/// A nested grid of other items.
final class GroupLayout extends RemoteItemLayout {
  const GroupLayout({required this.size});

  @override
  final RemoteItemSize size;

  @override
  T accept<T>(RemoteLayoutVisitor<T> visitor) => visitor.visitGroup(this);
}
