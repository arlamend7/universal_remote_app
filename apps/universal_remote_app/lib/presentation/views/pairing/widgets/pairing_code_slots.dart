import 'package:flutter/material.dart';

class PairingCodeSlots extends StatelessWidget {
  const PairingCodeSlots({super.key, required this.code, required this.length});

  final String code;
  final int length;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      children: [
        for (var index = 0; index < length; index++)
          Expanded(child: _slot(context, index)),
      ],
    ),
  );

  Widget _slot(BuildContext context, int index) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: index == code.length ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: Text(
        index < code.length ? code[index].toUpperCase() : '',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
