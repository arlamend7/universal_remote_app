import 'package:flutter/material.dart';

/// Gives sheet actions a common size, shape and reading order.
class AppSheetActions extends StatelessWidget {
  const AppSheetActions({super.key, required this.primary, this.secondary});

  final Widget primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _layout);

  Widget _layout(BuildContext context, BoxConstraints constraints) {
    final other = secondary;
    if (other == null) {
      return SizedBox(width: double.infinity, child: primary);
    }
    if (constraints.maxWidth < 288 ||
        MediaQuery.textScalerOf(context).scale(14) > 18) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [other, primary],
      );
    }
    return Row(
      spacing: 10,
      children: [
        Expanded(child: other),
        Expanded(child: primary),
      ],
    );
  }
}
