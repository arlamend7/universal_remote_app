import 'package:flutter/material.dart';

import '../../configuration/remote_element_style.dart';

/// An element's own appearance: visibility, border and corner radius.
///
/// With [inset], the content keeps clear of the border, for elements such as
/// information text that would otherwise run underneath it.
class StyledElement extends StatelessWidget {
  const StyledElement({
    super.key,
    required this.style,
    required this.child,
    this.inset = false,
  });

  /// Space between a drawn border and inset content.
  static const borderSpacing = 4.0;

  final RemoteElementStyle? style;
  final Widget child;
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final appearance = style;
    if (appearance == null) {
      return child;
    }
    if (!appearance.visible) {
      return const SizedBox.shrink();
    }
    final radius = BorderRadius.circular(appearance.cornerRadius);
    return ClipRRect(
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: appearance.borderWidth == 0
              ? null
              : Border.all(
                  width: appearance.borderWidth,
                  color: Theme.of(context).colorScheme.primary,
                ),
        ),
        child: _content(appearance),
      ),
    );
  }

  Widget _content(RemoteElementStyle appearance) {
    if (!inset || appearance.borderWidth == 0) {
      return child;
    }
    return Padding(
      padding: EdgeInsets.all(appearance.borderWidth + borderSpacing),
      child: child,
    );
  }
}
