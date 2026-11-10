import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

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
  final PointerDownEventListener onStart;
  final PointerMoveEventListener onUpdate;
  final PointerUpEventListener onEnd;
  final PointerCancelEventListener onCancel;

  static const double _hitSize = 32;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Resize $label',
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          if (enabled)
            EagerGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                  (_) {},
                ),
        },
        child: _listener(colors),
      ),
    );
  }

  Widget _listener(ColorScheme colors) => Listener(
    onPointerDown: enabled ? onStart : null,
    onPointerMove: enabled ? onUpdate : null,
    onPointerUp: enabled ? onEnd : null,
    onPointerCancel: enabled ? onCancel : null,
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
  );
}
