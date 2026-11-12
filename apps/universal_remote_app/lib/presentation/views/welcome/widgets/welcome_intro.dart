import 'package:flutter/material.dart';

class WelcomeIntro extends StatelessWidget {
  const WelcomeIntro({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      spacing: 12,
      children: [
        _mark(colors),
        Text(
          'UNIVERSAL REMOTE',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        Semantics(
          header: true,
          child: Text(
            'Welcome to your TV',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          'Control your TV from your phone with a remote you can make your own.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _mark(ColorScheme colors) => Container(
    width: 82,
    height: 82,
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: colors.outlineVariant),
      boxShadow: [
        BoxShadow(color: colors.primary.withValues(alpha: .16), blurRadius: 48),
      ],
    ),
    child: Icon(Icons.live_tv_rounded, size: 38, color: colors.primary),
  );
}
