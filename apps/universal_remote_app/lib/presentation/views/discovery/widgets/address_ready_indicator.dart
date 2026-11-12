import 'package:flutter/material.dart';

/// Confirms that the typed IP address is well formed.
class AddressReadyIndicator extends StatelessWidget {
  const AddressReadyIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Semantics(
      label: 'Address format OK',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text(
              'OK',
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontFamily: 'monospace',
                fontFamilyFallback: const ['Menlo', 'Courier New'],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const SizedBox.square(dimension: 9),
            ),
          ],
        ),
      ),
    );
  }
}
