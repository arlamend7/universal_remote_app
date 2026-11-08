import 'remote_item_layout.dart';
import 'remote_layout_visitor.dart';
import 'remote_item_size.dart';

/// An explanation shown where a control is not supported yet.
final class UnavailableLayout extends RemoteItemLayout {
  const UnavailableLayout({this.size});

  @override
  final RemoteItemSize? size;

  @override
  T accept<T>(RemoteLayoutVisitor<T> visitor) => visitor.visitUnavailable(this);
}
