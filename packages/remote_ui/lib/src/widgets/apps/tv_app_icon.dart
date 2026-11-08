import 'package:flutter/material.dart';

/// A local app badge also works for saved shortcuts and offline previews.
class TvAppIcon extends StatelessWidget {
  const TvAppIcon({
    super.key,
    required this.appId,
    required this.name,
    this.size = 28,
  });

  final String appId;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground, glyph) = _appearance(colors);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size * .24),
        ),
        child: Text(
          glyph,
          style: TextStyle(
            color: foreground,
            fontSize: size * .46,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }

  (Color, Color, String) _appearance(ColorScheme colors) {
    final title = name.split(' - ').first.trim();
    final identity = switch (appId.toLowerCase()) {
      'netflix' => 'netflix',
      'youtube' => 'youtube',
      _ => title.toLowerCase(),
    };
    return switch (identity) {
      'netflix' => (const Color(0xffb20710), Colors.white, 'N'),
      'youtube' => (const Color(0xffbd2028), Colors.white, '▶'),
      'spotify' => (const Color(0xff17663b), Colors.white, '♫'),
      'apple tv' => (const Color(0xff292b31), Colors.white, 'TV'),
      'bell fibe tv' => (const Color(0xff14528c), Colors.white, 'B'),
      _ => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
        _initial(title),
      ),
    };
  }

  String _initial(String title) =>
      title.isEmpty ? '?' : title.characters.first.toUpperCase();
}
