import 'dart:math' as math;

import 'package:flutter/material.dart';

class EmptySlotOutline extends CustomPainter {
  const EmptySlotOutline(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1),
          const Radius.circular(14),
        ),
      );
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      for (double start = 0; start < metric.length; start += 6) {
        canvas.drawPath(
          metric.extractPath(start, math.min(start + 3, metric.length)),
          pen,
        );
      }
    }
  }

  @override
  bool shouldRepaint(EmptySlotOutline oldDelegate) =>
      oldDelegate.color != color;
}
