import 'package:flutter/material.dart';
import 'package:remote_ui/remote_ui.dart' show RemoteTabsTheme;

import 'app_palette.dart';
import 'accent_slider_thumb.dart';

/// Warm paper and forest-ink palette shared with the portfolio, tinted by an
/// accent the user can change at any time.
abstract final class AppThemes {
  static const defaultAccent = 0xff245b45;

  /// Offered in the top bar; any stored ARGB value is still honoured.
  static const accents = <({String name, int value})>[
    (name: 'Forest', value: defaultAccent),
    (name: 'Ocean', value: 0xff1f5f8b),
    (name: 'Indigo', value: 0xff4455b8),
    (name: 'Violet', value: 0xff7a4ab8),
    (name: 'Rose', value: 0xffb83a63),
    (name: 'Amber', value: 0xff914c00),
    (name: 'Teal', value: 0xff00796b),
    (name: 'Slate', value: 0xff475569),
  ];

  static const quickAccents = [
    (name: 'Turquoise', value: 0xff4bd2c0),
    (name: 'Mint', value: 0xff70f4e3),
    (name: 'Peach', value: 0xffffb299),
    (name: 'Clay', value: 0xffd17a57),
    (name: 'Coral', value: 0xffffad94),
    (name: 'Ice', value: 0xff8cf6eb),
  ];

  static const hueSpectrum = [
    Color(0xffff0000),
    Color(0xffffff00),
    Color(0xff00ff00),
    Color(0xff00ffff),
    Color(0xff0000ff),
    Color(0xffff00ff),
    Color(0xffff0000),
  ];

  static SliderThemeData spectrumSlider(ThemeData theme) =>
      theme.sliderTheme.copyWith(
        activeTrackColor: Colors.transparent,
        inactiveTrackColor: Colors.transparent,
        thumbShape: AccentSliderThumb(
          fill: theme.colorScheme.surface,
          outline: theme.colorScheme.onSurface,
        ),
      );

  static ThemeData get dark => build(Brightness.dark, defaultAccent);
  static ThemeData get light => build(Brightness.light, defaultAccent);

  static ThemeData build(Brightness brightness, int accentValue) {
    final dark = brightness == Brightness.dark;
    final accent = Color(accentValue);
    final palette = dark ? _dark() : _light();
    final primary = _accessible(accent, palette, dark);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: _on(primary),
      primaryContainer: Color.lerp(palette.surface, primary, .16),
      onPrimaryContainer: palette.text,
      secondary: primary,
      onSecondary: _on(primary),
      secondaryContainer: Color.lerp(palette.surface, primary, .2),
      onSecondaryContainer: palette.text,
      error: dark ? const Color(0xffffb4ab) : const Color(0xffba1a1a),
      onError: dark ? const Color(0xff690005) : Colors.white,
      surface: palette.surface,
      onSurface: palette.text,
      onSurfaceVariant: palette.muted,
      outline: palette.border,
      outlineVariant: palette.border,
      surfaceContainerLowest: palette.card,
      surfaceContainerLow: palette.low,
      surfaceContainer: palette.low,
      surfaceContainerHigh: palette.high,
      surfaceContainerHighest: palette.high,
    );
    return _theme(scheme, palette);
  }

  static ThemeData _theme(ColorScheme scheme, AppPalette palette) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final button = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12),
      ),
      shape: WidgetStatePropertyAll(shape),
    );
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [_tabs(scheme)],
      scaffoldBackgroundColor: scheme.surface,
      iconTheme: IconThemeData(color: scheme.primary),
      dividerColor: palette.border.withValues(alpha: .6),
      visualDensity: VisualDensity.standard,
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.border),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: button),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: button.copyWith(
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.disabled)
                  ? scheme.outlineVariant.withValues(alpha: .4)
                  : scheme.outlineVariant,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: button),
      elevatedButtonTheme: ElevatedButtonThemeData(style: button),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(44),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: shape,
          side: BorderSide.none,
          backgroundColor: scheme.surface,
          selectedBackgroundColor: scheme.primary,
          selectedForegroundColor: scheme.onPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surface,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 4,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
    );
  }

  static RemoteTabsTheme _tabs(ColorScheme colors) {
    final button = TextButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    return RemoteTabsTheme(
      track: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      selected: button.copyWith(
        backgroundColor: WidgetStatePropertyAll(colors.primary),
        foregroundColor: WidgetStatePropertyAll(colors.onPrimary),
      ),
      unselected: button.copyWith(
        foregroundColor: WidgetStatePropertyAll(colors.onSurfaceVariant),
      ),
    );
  }

  static AppPalette _light() => const AppPalette(
    surface: Color(0xfff9f9f7),
    low: Color(0xfff4f4f2),
    high: Color(0xffeeeeec),
    card: Color(0xffffffff),
    text: Color(0xff1a1c1b),
    muted: Color(0xff414844),
    border: Color(0xffc1c8c3),
  );

  static AppPalette _dark() => const AppPalette(
    surface: Color(0xff121416),
    low: Color(0xff17191b),
    high: Color(0xff292c2f),
    card: Color(0xff1d1f21),
    text: Color(0xffe1e3e5),
    muted: Color(0xffb8c4c3),
    border: Color(0xff394143),
  );

  /// Backgrounds never change with the accent. The accent is moved toward white
  /// (dark) or black (light) only as far as needed for WCAG AA (4.5:1) against
  /// every background it is drawn on, so icons, text and buttons stay legible.
  static Color _accessible(Color accent, AppPalette palette, bool dark) {
    final backgrounds = [
      palette.surface,
      palette.low,
      palette.high,
      palette.card,
    ];
    final target = dark ? Colors.white : Colors.black;
    for (var step = 0; step <= 20; step++) {
      final candidate = Color.lerp(accent, target, step / 20)!;
      final tinted = [
        ...backgrounds,
        Color.lerp(palette.surface, candidate, .16)!,
        Color.lerp(palette.surface, candidate, .2)!,
      ];
      if (tinted.every((b) => contrast(candidate, b) >= minimumContrast)) {
        return candidate;
      }
    }
    return target;
  }

  static const minimumContrast = 4.5;

  /// WCAG 2.x contrast ratio.
  static double contrast(Color a, Color b) {
    final light = a.computeLuminance(), other = b.computeLuminance();
    final hi = light > other ? light : other;
    final lo = light > other ? other : light;
    return (hi + .05) / (lo + .05);
  }

  static Color _on(Color color) =>
      contrast(color, Colors.white) >= contrast(color, const Color(0xff002218))
      ? Colors.white
      : const Color(0xff002218);
}
