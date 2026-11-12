import 'package:flutter/material.dart';

class ConnectionIssuePage extends StatelessWidget {
  const ConnectionIssuePage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.actions,
    this.details,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<Widget> actions;
  final Widget? details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            Text(title, style: theme.textTheme.titleMedium),
            Text(description),
            if (details != null) details!,
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
      ),
    );
  }
}
