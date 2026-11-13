import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

/// Chooses how an item's elements are arranged. It never changes the item's
/// size or place on the grid.
class PositionPicker extends StatelessWidget {
  const PositionPicker({
    super.key,
    required this.position,
    required this.onChanged,
  });

  final ItemAxis position;
  final ValueChanged<ItemAxis> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Text('Position', style: Theme.of(context).textTheme.bodyLarge),
        SegmentedButton<ItemAxis>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: ItemAxis.horizontal,
              label: Text('Horizontal'),
              icon: Icon(Icons.view_column_outlined),
            ),
            ButtonSegment(
              value: ItemAxis.vertical,
              label: Text('Vertical'),
              icon: Icon(Icons.view_agenda_outlined),
            ),
          ],
          selected: {position},
          onSelectionChanged: (selection) => onChanged(selection.single),
        ),
      ],
    ),
  );
}
