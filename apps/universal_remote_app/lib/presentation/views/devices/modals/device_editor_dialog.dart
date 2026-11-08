import 'package:flutter/material.dart';

import 'package:remote_ui/remote_ui.dart';

import '../viewmodels/device_editor_viewmodel.dart';
import '../forms/device_editor_fields.dart';

class DeviceEditorDialog extends StatelessWidget {
  const DeviceEditorDialog({
    super.key,
    required this.model,
    required this.onSubmit,
    required this.onCancel,
  });
  final DeviceEditorViewModel model;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  @override
  Widget build(BuildContext context) => AppSheet(
    title: model.editing ? 'Connection settings' : 'Connect by IP',
    child: _content(),
  );
  Widget _content() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DeviceEditorFields(model: model),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: onSubmit,
        child: Text(model.editing ? 'Save details' : 'Connect'),
      ),
      TextButton(onPressed: onCancel, child: const Text('Cancel')),
    ],
  );
}
