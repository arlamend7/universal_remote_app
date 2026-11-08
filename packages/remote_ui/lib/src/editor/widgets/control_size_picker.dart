import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

class ControlSizePicker extends StatelessWidget {
  const ControlSizePicker({
    super.key,
    required this.item,
    required this.columns,
    required this.onChanged,
  });
  final GridItem item;
  final int columns;
  final void Function(int width, int height) onChanged;

  /// Whether the definition accepts this placed size (rotation swaps the
  /// content's width and height).
  bool _accepts(int width, int height) => item.quarterTurns.isOdd
      ? item.definition.accepts(height, width)
      : item.definition.accepts(width, height);
  int get _maximumHeight => item.quarterTurns.isOdd ? 4 : 16;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Width'),
      Wrap(
        spacing: 8,
        children: [
          for (var width = 1; width <= columns; width++)
            if (width == item.w || _accepts(width, item.h)) _choice(width),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          const Expanded(child: Text('Height')),
          IconButton(
            tooltip: 'Make shorter',
            onPressed: _accepts(item.w, item.h - 1)
                ? () => onChanged(item.w, item.h - 1)
                : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(_accepts(item.w, item.h - 1) ? 'Taller' : 'Compact'),
          IconButton(
            tooltip: 'Make taller',
            onPressed: item.h < _maximumHeight && _accepts(item.w, item.h + 1)
                ? () => onChanged(item.w, item.h + 1)
                : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    ],
  );
  Widget _choice(int width) => ChoiceChip(
    label: Text(switch (width) {
      1 => 'Slim',
      2 => 'Half',
      3 => 'Wide',
      _ => 'Full',
    }),
    selected: width == item.w,
    onSelected: (_) => onChanged(width, item.h),
  );
}
