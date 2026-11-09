import 'package:flutter/material.dart';

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
    final custom = accentValue != defaultAccent;
    final palette = dark ? _dark(accent, custom) : _light();
    final primary = dark
        ? (custom
              ? Color.lerp(accent, Colors.white, .4)!
              : const Color(0xff69d4c9))
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
          selectedBackgroundColor: scheme.surfaceContainerHighest,
          selectedForegroundColor: scheme.primary,
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
        surface: Color(0xff121416),
        low: Color(0xff17191b),
        high: Color(0xff292c2f),
        card: Color(0xff1d1f21),
        text: Color(0xffe1e3e5),
        muted: Color(0xffb8c4c3),
        border: Color(0xff394143),
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
