import 'package:flutter/material.dart';

/// A 3×3 grid of dots, the universal "drag to resize" affordance.
class NineDotsPainter extends CustomPainter {
  const NineDotsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final stepX = size.width / 3;
    final stepY = size.height / 3;
    for (var row = 0; row < 3; row++) {
      for (var column = 0; column < 3; column++) {
        final center = Offset(stepX * (column + .5), stepY * (row + .5));
        canvas.drawCircle(center, 1.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(NineDotsPainter oldDelegate) => oldDelegate.color != color;
}
