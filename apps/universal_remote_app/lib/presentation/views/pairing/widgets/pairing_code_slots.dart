import 'package:flutter/material.dart';

class PairingCodeSlots extends StatelessWidget {
  const PairingCodeSlots({
    super.key,
    required this.code,
    required this.length,
    this.inline = false,
  });

  final String code;
  final int length;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        for (var index = 0; index < length; index++)
          Expanded(child: _slot(context, index)),
      ],
    );
    if (!inline) {
      return ExcludeSemantics(child: row);
    }
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: row,
        ),
      ),
    );
  }

  Widget _slot(BuildContext context, int index) {
    final colors = Theme.of(context).colorScheme;
    final text = index < code.length
        ? code[index].toUpperCase()
        : (inline ? '•' : '');
    final label = Text(text, style: Theme.of(context).textTheme.titleLarge);
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      alignment: Alignment.center,
      decoration: inline
          ? null
          : BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: index == code.length
                    ? colors.primary
                    : colors.outlineVariant,
              ),
            ),
      child: label,
    );
  }
}
