import 'package:flutter/material.dart';

import '../../configuration/remote_element_style.dart';

class StyledElement extends StatelessWidget {
  const StyledElement({super.key, required this.style, required this.child});

  final RemoteElementStyle? style;
  final Widget child;

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
        child: child,
      ),
    );
  }
}
