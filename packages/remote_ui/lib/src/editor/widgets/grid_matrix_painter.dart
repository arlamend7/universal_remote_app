import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../layout/models/grid_layout.dart';

class GridMatrixPainter extends CustomPainter {
  const GridMatrixPainter({
    required this.layout,
    required this.columns,
    required this.rows,
    required this.colors,
  });

  final GridLayout layout;
  final int columns, rows;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(
      size.width / math.min(columns, 16),
      size.height / math.min(rows, 24),
    );
    final left = (size.width - math.min(columns, 16) * side) / 2;
    final top = (size.height - math.min(rows, 24) * side) / 2;
    final empty = Paint()..color = colors.surfaceContainerHighest;
    final occupied = Paint()..color = colors.primary;
    for (var y = 0; y < math.min(rows, 24); y++) {
      for (var x = 0; x < math.min(columns, 16); x++) {
        final cell = Rect.fromLTWH(
          left + x * side,
          top + y * side,
          side,
          side,
        ).deflate(math.min(2, side / 6));
        canvas.drawRRect(
          RRect.fromRectAndRadius(cell, const Radius.circular(3)),
          _occupied(x, y) ? occupied : empty,
        );
      }
    }
  }

  bool _occupied(int x, int y) => layout.items.any(
    (item) =>
        x >= item.x &&
        x < item.x + item.w &&
        y >= item.y &&
        y < item.y + item.h,
  );

  @override
  bool shouldRepaint(GridMatrixPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.columns != columns ||
      oldDelegate.rows != rows ||
      oldDelegate.colors != colors;
}
