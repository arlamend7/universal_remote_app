import 'remote_item_size.dart';
import 'remote_layout_visitor.dart';

/// How an item's elements are arranged and drawn. Each subtype owns only the
/// settings its own arrangement needs; there is no shared bag of options.
abstract class RemoteItemLayout {
  const RemoteItemLayout();

  /// Fixed size of arrangements that are not a single row or column of
  /// elements. Null means the size follows from the item's elements.
  RemoteItemSize? get size => null;

  /// The height in logical pixels the arrangement needs to stay usable, given
  /// the width of one grid cell. Zero means the cell height is enough.
  double minimumHeight({
    required int width,
    required double cellWidth,
    required double gap,
    required Map<String, String> settings,
  }) => 0;

  /// Whether an item with [elementCount] elements can arrange them either
  /// horizontally or vertically. Layouts with their own geometry (pads, dials,
  /// touch surfaces, groups) keep a single arrangement.
  bool supportsPosition(int elementCount) => false;

  /// Double dispatch, so a consumer must handle every layout.
  T accept<T>(RemoteLayoutVisitor<T> visitor);
}
