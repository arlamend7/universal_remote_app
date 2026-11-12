import 'package:flutter/material.dart';

class SetupStepHeader extends StatelessWidget {
  const SetupStepHeader({
    super.key,
    required this.step,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.action,
  });

  final int step;
  final String title;
  final VoidCallback? onBack;
  final String? subtitle;

  /// Optional 44 px trailing button, balanced by the Back button.
  final Widget? action;

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
              _backButton(),
              Expanded(child: _title(theme)),
              action ?? const SizedBox(width: 44),
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

  Widget _backButton() {
    final back = onBack;
    if (back == null) {
      return const SizedBox(width: 44);
    }
    return IconButton.filledTonal(
      tooltip: 'Back',
      onPressed: back,
      icon: const Icon(Icons.chevron_left),
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
