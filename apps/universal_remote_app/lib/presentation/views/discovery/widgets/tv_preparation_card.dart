import 'package:flutter/material.dart';

class TvPreparationCard extends StatelessWidget {
  const TvPreparationCard({
    super.key,
    required this.step,
    required this.icon,
    required this.title,
    required this.child,
  });

  final int step;
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          spacing: 4,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 8,
              children: [
                CircleAvatar(
                  radius: 12,
                  child: Text('$step', style: theme.textTheme.labelMedium),
                ),
                Icon(icon, color: theme.colorScheme.primary),
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }
}
