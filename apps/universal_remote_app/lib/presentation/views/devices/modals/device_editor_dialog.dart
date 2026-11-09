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
    child: DeviceEditorFields(model: model),
    footer: _actions(),
  );
  Widget _actions() => AppSheetActions(
    secondary: OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
    primary: FilledButton(
      onPressed: model.checking.value ? null : onSubmit,
      child: Text(_submitLabel),
    ),
  );
  String get _submitLabel {
    if (model.checking.value) {
      return 'Checking TV…';
    }
    return model.editing ? 'Save details' : 'Connect';
  }
}
