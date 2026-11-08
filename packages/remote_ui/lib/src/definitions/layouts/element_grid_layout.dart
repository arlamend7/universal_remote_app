import 'remote_item_layout.dart';
import 'remote_item_size.dart';
import 'remote_layout_visitor.dart';

/// The item's elements as a grid, such as a numeric keypad.
final class ElementGridLayout extends RemoteItemLayout {
  const ElementGridLayout({required this.columns, required this.size});

  /// Width-to-height ratio of each cell.
  static const aspectRatio = 1.1;

  final int columns;

  @override
  final RemoteItemSize size;

  @override
  double minimumHeight({
    required int width,
    required double cellWidth,
    required double gap,
    required Map<String, String> settings,
  }) =>
      ((width * cellWidth + (width - 1) * gap) / columns / aspectRatio) *
      size.height;

  @override
  T accept<T>(RemoteLayoutVisitor<T> visitor) => visitor.visitElementGrid(this);
}
