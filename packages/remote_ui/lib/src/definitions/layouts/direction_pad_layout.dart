import 'pad_shape.dart';
import 'remote_item_layout.dart';
import 'remote_layout_visitor.dart';
import 'remote_item_size.dart';

/// Four direction keys around a centre key.
final class DirectionPadLayout extends RemoteItemLayout {
  const DirectionPadLayout(this.shape, {required this.size});

  /// Smallest side that keeps the four direction keys accessible.
  static const minimumSide = 144.0;

  /// Height of the optional Home / Back shortcut row.
  static const shortcutRow = 48.0;

  final PadShape shape;

  @override
  final RemoteItemSize size;

  @override
  double minimumHeight({
    required int width,
    required double cellWidth,
    required double gap,
    required Map<String, String> settings,
  }) => minimumSide + (settings['shortcuts'] == 'true' ? shortcutRow : 0);

  @override
  T accept<T>(RemoteLayoutVisitor<T> visitor) =>
      visitor.visitDirectionPad(this);
}
