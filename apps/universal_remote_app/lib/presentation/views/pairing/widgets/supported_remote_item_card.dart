import 'package:flutter/material.dart';
import 'package:remote_ui/remote_ui.dart';

class SupportedRemoteItemCard extends StatelessWidget {
  const SupportedRemoteItemCard({
    super.key,
    required this.definition,
    required this.model,
  });

  final RemoteItemDefinition<Object> definition;
  final GridRemoteViewModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          spacing: 6,
          children: [
            Icon(_icon(), color: theme.colorScheme.primary),
            Text(definition.name, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  IconData _icon() {
    final context = RemoteElementContext(remote: model.remote);
    for (final element in definition.elements) {
      final icon = switch (element) {
        RemoteAction<Object>() => model.resolve(element, context)?.icon,
        _ => element.icon?.call(context),
      };
      if (icon != null) {
        return icon;
      }
    }
    return Icons.tune;
  }
}
