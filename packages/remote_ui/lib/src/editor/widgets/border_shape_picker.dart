import 'package:flutter/material.dart';

import '../../configuration/enums/remote_border_shape.dart';

class BorderShapePicker extends StatelessWidget {
  const BorderShapePicker({
    super.key,
    required this.radius,
    required this.onChanged,
  });

  final double radius;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<double>(
    key: ValueKey(radius),
    initialValue: radius,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Border shape'),
    items: [
      for (final shape in RemoteBorderShape.values)
        DropdownMenuItem(value: shape.radius, child: Text(shape.label)),
      if (!RemoteBorderShape.values.any((shape) => shape.radius == radius))
        DropdownMenuItem(value: radius, child: const Text('Current shape')),
    ],
    onChanged: (value) {
      if (value != null) {
        onChanged(value);
      }
    },
  );
}
