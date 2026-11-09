import 'package:flutter/material.dart';

import '../../../../shared/themes/app_themes.dart';
import 'accent_dot.dart';

class AccentSwatches extends StatelessWidget {
  const AccentSwatches({
    super.key,
    required this.value,
    required this.onSelected,
    this.custom,
  });

  final VoidCallback? custom;
  final int value;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 0,
    runSpacing: 6,
    alignment: WrapAlignment.spaceBetween,
    children: [
      ...AppThemes.quickAccents.map(_swatch),
      if (custom != null)
        IconButton.outlined(
          tooltip: 'Custom Accent',
          onPressed: custom,
          icon: const Icon(Icons.palette_outlined),
        ),
    ],
  );

  Widget _swatch(({String name, int value}) accent) => Semantics(
    selected: accent.value == value,
    child: IconButton(
      tooltip: accent.name,
      onPressed: () => onSelected(accent.value),
      icon: AccentDot(
        color: Color(accent.value),
        size: 34,
        selected: accent.value == value,
      ),
    ),
  );
}
