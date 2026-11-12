import 'package:flutter/material.dart';

import '../viewmodels/device_editor_viewmodel.dart';
import 'advanced_connection_fields.dart';
import 'legacy_connection_fields.dart';

/// Name and transport options kept out of the Connect by IP page.
class ConnectionSettingsFields extends StatelessWidget {
  const ConnectionSettingsFields({super.key, required this.model});

  final DeviceEditorViewModel model;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 8,
    children: [
      TextField(
        controller: model.name,
        decoration: const InputDecoration(labelText: 'Name'),
      ),
      if (model.showsAdvancedSetup) ...[
        LegacyConnectionFields(model: model),
        AdvancedConnectionFields(model: model),
      ],
    ],
  );
}
