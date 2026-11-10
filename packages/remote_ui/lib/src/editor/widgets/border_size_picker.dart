import 'package:flutter/material.dart';

class BorderSizePicker extends StatelessWidget {
  const BorderSizePicker({
    super.key,
    required this.width,
    required this.onChanged,
  });

  final double width;
  final ValueChanged<double> onChanged;

  static final _sizes = <double, String>{
    0: 'None',
    1: 'Thin',
    2: 'Small',
    3: 'Normal',
    4: 'Bold',
  };

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<double>(
    key: ValueKey(width),
    initialValue: width,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Border size'),
    items: [
      for (final size in _sizes.entries)
        DropdownMenuItem(value: size.key, child: Text(size.value)),
      if (!_sizes.containsKey(width))
        DropdownMenuItem(value: width, child: const Text('Current size')),
    ],
    onChanged: (value) {
      if (value != null) {
        onChanged(value);
      }
    },
  );
}
