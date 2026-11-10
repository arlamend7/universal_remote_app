import 'package:flutter/material.dart';

/// Scrolls a canvas axis in small frame-sized steps while a drag is near its edge.
final class GridDragScroll {
  const GridDragScroll(this.scrollable);

  final ScrollableState scrollable;

  bool advance(Offset pointer, double seconds) {
    final box = scrollable.context.findRenderObject();
    final position = scrollable.position;
    if (box is! RenderBox || !box.hasSize || !position.hasContentDimensions) {
      return false;
    }
    final local = box.globalToLocal(pointer);
    final horizontal =
        axisDirectionToAxis(scrollable.axisDirection) == Axis.horizontal;
    final coordinate = horizontal ? local.dx : local.dy;
    final extent = horizontal ? box.size.width : box.size.height;
    final direction = axisDirectionIsReversed(scrollable.axisDirection)
        ? -1
        : 1;
    final speed = _speed(coordinate, extent) * direction;
    final next = (position.pixels + speed * seconds).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (next == position.pixels) {
      return false;
    }
    position.jumpTo(next);
    return true;
  }

  double _speed(double coordinate, double extent) {
    const zone = 72.0;
    const outside = 40.0;
    const maximum = 900.0;
    if (coordinate < -outside || coordinate > extent + outside) {
      return 0;
    }
    final start = ((zone - coordinate) / zone).clamp(0.0, 1.0);
    final end = ((coordinate - extent + zone) / zone).clamp(0.0, 1.0);
    return (end - start) * maximum;
  }
}
