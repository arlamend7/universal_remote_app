import 'remote_item_layout.dart';
import 'remote_item_size.dart';
import 'remote_layout_visitor.dart';

/// The item's elements in one row or column, in registration order. Each
/// element takes space in proportion to its slots.
///
/// An [adaptive] layout picks its direction from the item's shape: taller than
/// wide runs top to bottom, wider than tall runs left to right (square keeps
/// the definition's own axis). Its elements are declared top to bottom and run
/// in reverse when horizontal, so "less" sits on the left of a rocker.
final class LinearLayout extends RemoteItemLayout {
  const LinearLayout({
    this.size,
    this.adaptive = false,
    this.reverseWhenHorizontal = true,
  });

  final bool adaptive, reverseWhenHorizontal;

  @override
  final RemoteItemSize? size;

  @override
  T accept<T>(RemoteLayoutVisitor<T> visitor) => visitor.visitLinear(this);
}
