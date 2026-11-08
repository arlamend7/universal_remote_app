import 'remote_item_layout.dart';
import 'remote_layout_visitor.dart';

/// Draws nothing; used for spacing and unknown saved items.
final class EmptyLayout extends RemoteItemLayout {
  const EmptyLayout();

  @override
  T accept<T>(RemoteLayoutVisitor<T> visitor) => visitor.visitEmpty(this);
}
