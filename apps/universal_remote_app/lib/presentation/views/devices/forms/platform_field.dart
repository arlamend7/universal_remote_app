import 'package:flutter/material.dart';

import '../viewmodels/device_editor_viewmodel.dart';

/// TV platform choice for a manually added TV.
class PlatformField extends StatelessWidget {
  const PlatformField({super.key, required this.model});

  final DeviceEditorViewModel model;

  static const _automatic = '';

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: model.provider.value ?? _automatic,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'TV platform'),
    items: [
      if (model.identifyAddress != null)
        const DropdownMenuItem(
          value: _automatic,
          child: Text('Detect automatically'),
        ),
      for (final entry in model.setups.entries)
        DropdownMenuItem(value: entry.key, child: Text(entry.value.label)),
    ],
    onChanged: model.checking.value ? null : _select,
  );

  void _select(String? value) {
    model.provider.value = value == _automatic ? null : value;
  }
}
