import 'package:flutter/material.dart';

import '../../../../shared/themes/app_themes.dart';
import '../viewmodels/settings_viewmodel.dart';
import 'accent_dot.dart';

/// The accent palette; the chosen swatch is outlined.
class AccentSwatches extends StatelessWidget {
  const AccentSwatches({super.key, required this.model});
  final SettingsViewModel model;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      for (final accent in AppThemes.accents)
        Tooltip(
          message: accent.name,
          child: InkResponse(
            onTap: () => model.setAccent(context, accent.value),
            child: AccentDot(
              color: Color(accent.value),
              size: 36,
              selected: accent.value == model.accent,
            ),
          ),
        ),
    ],
  );
}
