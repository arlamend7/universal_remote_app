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
  int get _minimumWidth => item.quarterTurns.isOdd
      ? WidgetCatalog.definition(item.layoutKind).minimumHeight
      : WidgetCatalog.definition(item.layoutKind).minimumWidth;
  int get _minimumHeight => item.quarterTurns.isOdd
      ? WidgetCatalog.definition(item.layoutKind).minimumWidth
      : WidgetCatalog.definition(item.layoutKind).minimumHeight;
  int get _maximumHeight => item.quarterTurns.isOdd ? 4 : 16;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Width'),
      Wrap(
        spacing: 8,
        children: [
          for (var width = _minimumWidth; width <= columns; width++)
            _choice(width),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          const Expanded(child: Text('Height')),
          IconButton(
            tooltip: 'Make shorter',
            onPressed: item.h > _minimumHeight
                ? () => onChanged(item.w, item.h - 1)
                : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(item.h == _minimumHeight ? 'Compact' : 'Taller'),
          IconButton(
            tooltip: 'Make taller',
            onPressed: item.h < _maximumHeight
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
