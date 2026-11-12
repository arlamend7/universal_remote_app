import 'package:flutter/material.dart';

class DeviceRowSurface extends StatelessWidget {
  const DeviceRowSurface({
    super.key,
    required this.highlighted,
    required this.onTap,
    required this.child,
    this.onLongPress,
  });

  final bool highlighted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final border = BorderSide(
      color: highlighted ? colors.primary : colors.outlineVariant,
    );
    return Material(
      shape: Border(top: border, bottom: border),
      color: highlighted
          ? colors.surfaceContainerHigh
          : colors.surfaceContainerLow,
      child: InkWell(onTap: onTap, onLongPress: onLongPress, child: child),
    );
  }
}
