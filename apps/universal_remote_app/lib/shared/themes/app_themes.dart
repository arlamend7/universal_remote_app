import 'package:flutter/material.dart';

import 'app_palette.dart';

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

  static ThemeData get dark => build(Brightness.dark, defaultAccent);
  static ThemeData get light => build(Brightness.light, defaultAccent);

  static ThemeData build(Brightness brightness, int accentValue) {
    final dark = brightness == Brightness.dark;
    final accent = Color(accentValue);
    final custom = accentValue != defaultAccent;
    final palette = dark ? _dark(accent, custom) : _light();
    final primary = dark
        ? (custom
              ? Color.lerp(accent, Colors.white, .4)!
              : const Color(0xffbce4cd))
        : accent;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: _on(primary),
      primaryContainer: Color.lerp(palette.surface, accent, dark ? .32 : .18),
      onPrimaryContainer: palette.text,
      secondary: primary,
      onSecondary: _on(primary),
      secondaryContainer: Color.lerp(palette.surface, accent, dark ? .4 : .22),
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
    const radius = 12.0;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
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
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: .14),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 4,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
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

  static AppPalette _dark(Color accent, bool custom) {
    if (!custom) {
      return const AppPalette(
        surface: Color(0xff101c17),
        low: Color(0xff17271e),
        high: Color(0xff253b2e),
        card: Color(0xff20342a),
        text: Color(0xffe1ede5),
        muted: Color(0xffb5c8bd),
        border: Color(0xff4c6658),
      );
    }
    Color tint(double amount, int base) =>
        Color.lerp(Color(base), accent, amount)!;
    return AppPalette(
      surface: tint(.10, 0xff101014),
      low: tint(.14, 0xff18181c),
      high: tint(.18, 0xff29292e),
      card: tint(.16, 0xff202025),
      text: const Color(0xfff2f2f5),
      muted: const Color(0xffc5c5cd),
      border: tint(.20, 0xff666670),
    );
  }

  static Color _on(Color color) =>
      ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? Colors.white
      : const Color(0xff002218);
}
