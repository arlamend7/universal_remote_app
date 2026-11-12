import 'package:flutter/material.dart';

import '../viewmodels/device_editor_viewmodel.dart';

/// Opt-in switches for TVs that only accept unencrypted transport.
class LegacyConnectionFields extends StatelessWidget {
  const LegacyConnectionFields({super.key, required this.model});

  final DeviceEditorViewModel model;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [_legacy(), if (!model.legacy.value) _legacyPointer()],
  );

  Widget _legacy() => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: const Text('Legacy connection'),
    subtitle: const Text(
      'Unencrypted transport. Use only on a trusted network.',
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
}
