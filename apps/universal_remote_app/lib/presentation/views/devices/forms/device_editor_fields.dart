import 'package:flutter/material.dart';

import '../viewmodels/device_editor_viewmodel.dart';
import 'advanced_connection_fields.dart';

class DeviceEditorFields extends StatelessWidget {
  const DeviceEditorFields({super.key, required this.model});
  final DeviceEditorViewModel model;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (!model.editing && model.setups.length > 1) _platform(),
      _name(),
      const SizedBox(height: 16),
      _address(),
      const SizedBox(height: 8),
      if (model.showsAdvancedSetup)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Advanced settings'),
          children: [
            _legacy(),
            if (!model.legacy.value) _legacyPointer(),
            AdvancedConnectionFields(model: model),
          ],
        ),
      if (model.error.value != null) _error(context),
    ],
  );
  Widget _platform() => DropdownButtonFormField<String>(
    initialValue: model.provider.value,
    decoration: const InputDecoration(labelText: 'TV platform'),
    items: [
      for (final entry in model.setups.entries)
        DropdownMenuItem(value: entry.key, child: Text(entry.value.label)),
    ],
    onChanged: (value) => model.provider.value = value,
  );

  Widget _name() => TextField(
    controller: model.name,
    decoration: const InputDecoration(labelText: 'Name'),
  );
  Widget _address() => TextField(
    controller: model.address,
    autocorrect: false,
    decoration: const InputDecoration(
      labelText: 'TV IP address',
      hintText: '192.168.1.100',
    ),
  );
  Widget _legacy() => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: const Text('Legacy connection'),
    subtitle: const Text(
      'Unencrypted port 3000. Use only on a trusted network.',
    ),
    value: model.legacy.value,
    onChanged: model.setLegacy,
  );
  Widget _legacyPointer() => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: const Text('Allow legacy navigation socket'),
    subtitle: const Text(
      'Some TVs require unencrypted navigation even when pairing uses TLS.',
    ),
    value: model.legacyPointer.value,
    onChanged: model.setLegacyPointer,
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
