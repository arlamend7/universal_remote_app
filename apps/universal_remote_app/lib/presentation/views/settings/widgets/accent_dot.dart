import 'package:flutter/material.dart';

class AccentDot extends StatelessWidget {
  const AccentDot({
    required this.color,
    required this.size,
    required this.selected,
  });
  final Color color;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(
        width: selected ? 3 : 1,
        color: selected
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.outlineVariant,
      ),
    ),
  );
}
