import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class MouseItemDrag extends Draggable<String> {
  const MouseItemDrag({
    super.key,
    required super.data,
    required super.child,
    required super.feedback,
    super.childWhenDragging,
    super.maxSimultaneousDrags,
    super.dragAnchorStrategy,
  });
  @override
  MultiDragGestureRecognizer createRecognizer(
    GestureMultiDragStartCallback onStart,
  ) => ImmediateMultiDragGestureRecognizer(
    supportedDevices: const {
      PointerDeviceKind.mouse,
      PointerDeviceKind.trackpad,
    },
  )..onStart = onStart;
}
