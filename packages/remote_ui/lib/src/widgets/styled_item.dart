import 'package:flutter/material.dart';

import '../configuration/remote_item_style.dart';

/// Applies an item's appearance to its outer container: background, border,
/// corner radius, padding, opacity and foreground colour. Live controls,
/// previews and the editor shell all use this one implementation.
///
/// Layering: outer decoration → clip → padding (clear of the border) →
/// content. The content decides its own arrangement and alignment; this
/// widget never rotates or rearranges it.
class StyledItem extends StatelessWidget {
  const StyledItem({super.key, required this.style, required this.child});
  final RemoteItemStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (style.isDefault) {
      return child;
    }
    final radius = BorderRadius.circular(style.cornerRadius);
    return Opacity(
      opacity: style.opacity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _background,
          borderRadius: radius,
          border: style.showBorder ? _border(context) : null,
        ),
        child: ClipRRect(borderRadius: radius, child: _padded()),
      ),
    );
  }

  Color? get _background {
    final background = style.background;
    if (!style.showBackground || background == null) {
      return null;
    }
    return Color(background);
  }

  /// Keeps the content clear of the border so they never overlap.
  Widget _padded() {
    final inset = style.padding + (style.showBorder ? style.borderWidth : 0);
    final content = Padding(padding: EdgeInsets.all(inset), child: child);
    final foreground = style.foreground;
    if (foreground == null) {
      return content;
    }
    return _foreground(content, Color(foreground));
  }

  Border _border(BuildContext context) =>
      Border.all(width: style.borderWidth, color: _borderColor(context));

  Color _borderColor(BuildContext context) {
    final color = style.borderColor;
    if (color == null) {
      return Theme.of(context).colorScheme.primary;
    }
    return Color(color);
  }

  Widget _foreground(Widget child, Color color) => IconTheme.merge(
    data: IconThemeData(color: color),
    child: DefaultTextStyle.merge(
      style: TextStyle(color: color),
      child: child,
    ),
  );
}
