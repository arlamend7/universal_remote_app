import 'package:flutter/material.dart';

import '../viewmodels/device_editor_viewmodel.dart';
import 'advanced_connection_fields.dart';
import 'legacy_connection_fields.dart';
import 'platform_field.dart';

class DeviceEditorFields extends StatelessWidget {
  const DeviceEditorFields({super.key, required this.model});
  final DeviceEditorViewModel model;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (!model.editing &&
          (model.setups.length > 1 || model.identifyAddress != null)) ...[
        PlatformField(model: model),
        const SizedBox(height: 16),
      ],
      _name(),
      const SizedBox(height: 16),
      _address(),
      const SizedBox(height: 8),
      if (model.showsAdvancedSetup)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Advanced settings'),
          children: [
            LegacyConnectionFields(model: model),
            AdvancedConnectionFields(model: model),
          ],
        ),
      if (model.error.value != null) _error(context),
    ],
  );

  Widget _name() => TextField(
    controller: model.name,
    decoration: const InputDecoration(labelText: 'Name'),
  );
  Widget _address() => TextField(
    controller: model.address,
    enabled: !model.checking.value,
    autocorrect: false,
    decoration: const InputDecoration(
      labelText: 'TV IP address',
      hintText: '192.168.1.100',
    ),
  );
  Widget _error(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: _errorLabel(context),
  );
  Widget _errorLabel(BuildContext context) => Text(
    model.error.value!,
    style: TextStyle(color: Theme.of(context).colorScheme.error),
  );
}
