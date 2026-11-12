import 'package:flutter/material.dart';

class SupportedRemoteItemCard extends StatelessWidget {
  const SupportedRemoteItemCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _content(theme),
        ),
      ),
    );
  }

  Widget _content(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 20,
    children: [
      Icon(icon, size: 25, color: theme.colorScheme.onSurface),
      Text(title, style: theme.textTheme.titleSmall),
    ],
  );
}
