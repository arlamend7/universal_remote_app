import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_app/shared/themes/app_themes.dart';

void main() {
  final accents = [
    ...AppThemes.accents.map((a) => a.value),
    ...AppThemes.quickAccents.map((a) => a.value),
    0xff000000,
    0xffffffff,
    0xffff0000,
    0xff00ff00,
    0xff0000ff,
    0xffffff00,
  ];

  test('backgrounds do not change with the accent', () {
    for (final brightness in Brightness.values) {
      final base = AppThemes.build(brightness, AppThemes.defaultAccent);
      for (final accent in accents) {
        final scheme = AppThemes.build(brightness, accent).colorScheme;
        expect(scheme.surface, base.colorScheme.surface);
        expect(
          scheme.surfaceContainerLow,
          base.colorScheme.surfaceContainerLow,
        );
        expect(
          scheme.surfaceContainerHigh,
          base.colorScheme.surfaceContainerHigh,
        );
        expect(
          scheme.surfaceContainerLowest,
          base.colorScheme.surfaceContainerLowest,
        );
      }
    }
  });

  test('every accent keeps WCAG AA contrast in both modes', () {
    for (final brightness in Brightness.values) {
      for (final accent in accents) {
        final s = AppThemes.build(brightness, accent).colorScheme;
        final pairs = {
          'primary/surface': (s.primary, s.surface),
          'primary/card': (s.primary, s.surfaceContainerLowest),
          'primary/high': (s.primary, s.surfaceContainerHigh),
          'onPrimary/primary': (s.onPrimary, s.primary),
          'text/surface': (s.onSurface, s.surface),
          'muted/surface': (s.onSurfaceVariant, s.surface),
          'onContainer/container': (s.onPrimaryContainer, s.primaryContainer),
          'primary/container': (s.primary, s.primaryContainer),
        };
        pairs.forEach((name, pair) {
          expect(
            AppThemes.contrast(pair.$1, pair.$2),
            greaterThanOrEqualTo(4.5),
            reason: '$name for ${accent.toRadixString(16)} in $brightness',
          );
        });
      }
    }
  });
}
