import 'package:flutter/material.dart';

class SessionRewardHighlight extends StatelessWidget {
  const SessionRewardHighlight({super.key, required this.duration});

  final String duration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Column(
      spacing: 4,
      children: [
        _badge(theme),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: reduceMotion ? 1 : .88, end: 1),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: _amount(theme),
        ),
      ],
    );
  }

  Widget _badge(ThemeData theme) {
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.primaryContainer,
        shape: StadiumBorder(side: BorderSide(color: colors.primary)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(
          'YOUR REWARD',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _amount(ThemeData theme) {
    final accent = theme.colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 10,
      children: [
        Icon(Icons.auto_awesome_rounded, color: accent, size: 20),
        Flexible(
          child: Text(
            duration,
            textAlign: TextAlign.center,
            style: theme.textTheme.displayMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Icon(Icons.auto_awesome_rounded, color: accent, size: 20),
      ],
    );
  }
}
