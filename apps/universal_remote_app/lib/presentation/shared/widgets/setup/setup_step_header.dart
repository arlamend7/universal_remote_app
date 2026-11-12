import 'package:flutter/material.dart';

class SetupStepHeader extends StatelessWidget {
  const SetupStepHeader({
    super.key,
    required this.step,
    required this.title,
    required this.onBack,
    this.subtitle,
  });

  final int step;
  final String title;
  final VoidCallback onBack;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        spacing: 14,
        children: [
          Row(
            spacing: 8,
            children: [
              IconButton.filledTonal(
                tooltip: 'Back',
                onPressed: onBack,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(child: _title(theme)),
              const SizedBox(width: 44),
            ],
          ),
          if (subtitle case final text?)
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ExcludeSemantics(child: _progress(theme.colorScheme)),
        ],
      ),
    );
  }

  Widget _title(ThemeData theme) => Column(
    spacing: 2,
    children: [
      Text(
        'STEP $step OF 4',
        textAlign: TextAlign.center,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      Semantics(
        header: true,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );

  Widget _progress(ColorScheme colors) => Row(
    spacing: 8,
    children: [
      for (var segment = 1; segment <= 4; segment++)
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: segment <= step ? colors.primary : colors.outlineVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SizedBox(height: 5),
          ),
        ),
    ],
  );
}
