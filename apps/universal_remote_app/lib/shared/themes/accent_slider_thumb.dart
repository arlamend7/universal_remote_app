import 'package:flutter/material.dart';

class AccentSliderThumb extends SliderComponentShape {
  const AccentSliderThumb({required this.fill, required this.outline});

  final Color fill;
  final Color outline;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(14, 28);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final thumb = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 14, height: 28),
      const Radius.circular(7),
    );
    context.canvas.drawRRect(thumb, Paint()..color = outline);
    context.canvas.drawRRect(thumb.deflate(2), Paint()..color = fill);
  }
}
