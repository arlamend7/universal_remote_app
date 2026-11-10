import 'package:flutter/material.dart';

class PreviewDotsPainter extends CustomPainter {
  const PreviewDotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = color;
    for (double y = 8; y < size.height; y += 16) {
      for (double x = 8; x < size.width; x += 16) {
        canvas.drawCircle(Offset(x, y), 1, dot);
      }
    }
  }

  @override
  bool shouldRepaint(PreviewDotsPainter oldDelegate) =>
      oldDelegate.color != color;
}
