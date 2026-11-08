import 'remote_item_layout.dart';
import 'remote_layout_visitor.dart';
import 'remote_item_size.dart';

/// A surface that turns drags and taps into pointer input.
final class TouchSurfaceLayout extends RemoteItemLayout {
  const TouchSurfaceLayout({required this.size});

  @override
  final RemoteItemSize size;

  @override
  T accept<T>(RemoteLayoutVisitor<T> visitor) =>
      visitor.visitTouchSurface(this);
}
