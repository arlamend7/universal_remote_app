import 'package:flutter/material.dart';

import '../../discovery/widgets/scanner_pulse.dart';
import '../../discovery/widgets/scanning_dots.dart';

/// Floating status shown at the bottom of discovery while a search runs.
class DiscoveryProgress extends StatelessWidget {
  const DiscoveryProgress({super.key});

  static const label = 'Searching for nearby devices';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 18, 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 18),
          ],
        ),
        child: Row(
          spacing: 14,
          children: [
            const ScannerPulse(),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const ScanningDots(),
          ],
        ),
      ),
    );
  }
}
