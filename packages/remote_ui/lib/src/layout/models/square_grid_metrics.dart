import 'dart:math' as math;

final class SquareGridMetrics {
  const SquareGridMetrics({required this.width, required this.height});

  static const minimumCell = 66.8;
  static const gap = 8.0;

  final double width, height;

  int get fittingColumns =>
      ((width + gap + .000001) / (minimumCell + gap)).floor();

  double cellSize(int columns) =>
      math.max(minimumCell, (width - gap * (columns - 1)) / columns);

  int fittingRows(double side) =>
      math.max(1, ((height + gap) / (side + gap)).floor());

  static double extent(int blocks, double side) => blocks * (side + gap) - gap;
}
