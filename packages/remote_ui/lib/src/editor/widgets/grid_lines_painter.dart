import 'package:flutter/material.dart';

class GridLinesPainter extends CustomPainter {
  GridLinesPainter({
    required this.columns,
    required this.rows,
    required this.cellWidth,
    required this.cellHeight,
    required this.color,
  });
  final int columns, rows;
  final double cellWidth, cellHeight;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = color.withValues(alpha: .3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .5;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < columns; x++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x * (cellWidth + 8),
              y * (cellHeight + 8),
              cellWidth,
              cellHeight,
            ),
            const Radius.circular(8),
          ),
          pen,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridLinesPainter oldDelegate) =>
      oldDelegate.columns != columns ||
      oldDelegate.rows != rows ||
      oldDelegate.cellWidth != cellWidth ||
      oldDelegate.cellHeight != cellHeight ||
      oldDelegate.color != color;
}
