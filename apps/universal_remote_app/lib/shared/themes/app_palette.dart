import 'package:flutter/material.dart';

/// Surface, text and border colors for one brightness.
final class AppPalette {
  const AppPalette({
    required this.surface,
    required this.low,
    required this.high,
    required this.card,
    required this.text,
    required this.muted,
    required this.border,
  });
  final Color surface, low, high, card, text, muted, border;
}
