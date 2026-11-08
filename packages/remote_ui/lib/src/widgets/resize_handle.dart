import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;

import 'nine_dots_painter.dart';

/// Nine-dot grip placed inside an item's bottom-right corner.
class ResizeHandle extends StatelessWidget {
  const ResizeHandle({
    super.key,
    required this.label,
    required this.enabled,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
  });

  final String label;
  final bool enabled;
  final GestureDragStartCallback onStart;
  final GestureDragUpdateCallback onUpdate;
  final GestureDragEndCallback onEnd;
  final VoidCallback onCancel;

  static const double _hitSize = 36;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Resize $label',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: enabled ? onStart : null,
        onPanUpdate: enabled ? onUpdate : null,
        onPanEnd: enabled ? onEnd : null,
        onPanCancel: onCancel,
        child: SizedBox(
          width: _hitSize,
          height: _hitSize,
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: CustomPaint(
                size: const Size.square(14),
                painter: NineDotsPainter(
                  enabled ? colors.onSurfaceVariant : colors.outline,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
