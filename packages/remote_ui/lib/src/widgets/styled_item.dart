import 'package:flutter/material.dart';

import '../configuration/remote_item_style.dart';

/// Applies an item's appearance (rotation, padding, background, border,
/// opacity and foreground colour) to its content. Live controls, previews and
/// the editor shell all use this one implementation.
class StyledItem extends StatelessWidget {
  const StyledItem({
    super.key,
    required this.style,
    required this.quarterTurns,
    required this.child,
  });
  final RemoteItemStyle style;
  final int quarterTurns;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final styled = _styled(context);
    if (quarterTurns == 0) {
      return styled;
    }
    return RotatedBox(quarterTurns: quarterTurns, child: styled);
  }

  Widget _styled(BuildContext context) {
    if (style.isDefault) {
      return child;
    }
    final foreground = style.foreground;
    final background = style.background;
    Widget content = Padding(
      padding: EdgeInsets.all(style.padding),
      child: child,
    );
    if (foreground != null) {
      content = _foreground(content, Color(foreground));
    }
    return Opacity(
      opacity: style.opacity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background == null ? null : Color(background),
          borderRadius: BorderRadius.circular(style.cornerRadius),
          border: style.showBorder ? _border(context) : null,
        ),
        child: content,
      ),
    );
  }

  Border _border(BuildContext context) => Border.all(
    width: style.borderWidth,
    color: style.borderColor == null
        ? Theme.of(context).colorScheme.outline
        : Color(style.borderColor!),
  );

  Widget _foreground(Widget child, Color color) => IconTheme.merge(
    data: IconThemeData(color: color),
    child: DefaultTextStyle.merge(
      style: TextStyle(color: color),
      child: child,
    ),
  );
}
