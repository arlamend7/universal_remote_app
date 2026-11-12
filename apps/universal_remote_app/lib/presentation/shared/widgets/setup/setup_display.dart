import 'package:flutter/material.dart';

/// A TV outline shared by the power check and the pairing code prompt.
class SetupDisplay extends StatelessWidget {
  const SetupDisplay({super.key, required this.child, this.minHeight = 136});

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: minHeight),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.outlineVariant, width: 2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: child,
            ),
            Container(width: 42, height: 12, color: colors.outlineVariant),
            Container(
              width: 108,
              height: 5,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
