import 'package:flutter/material.dart';

class TvPreparationCard extends StatelessWidget {
  const TvPreparationCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.confirmed = false,
    this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool confirmed;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trailing = Icon(icon, color: colors.primary);
    final change = onChanged;
    if (change != null) {
      return Card(
        child: CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(title),
          subtitle: Text(description),
          secondary: trailing,
          value: confirmed,
          onChanged: change,
        ),
      );
    }
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: confirmed,
          onChanged: null,
          fillColor: confirmed ? WidgetStatePropertyAll(colors.primary) : null,
          checkColor: colors.onPrimary,
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: trailing,
      ),
    );
  }
}
