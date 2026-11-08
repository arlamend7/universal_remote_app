import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../viewmodels/device_editor_viewmodel.dart';
import 'device_editor.dart';
import 'device_editor_dialog.dart';

class DeviceEditorState extends State<DeviceEditor> {
  late final DeviceEditorViewModel model;
  @override
  void initState() {
    super.initState();
    final device = widget.device;
    final registry = widget.dependencies.providers;
    model = DeviceEditorViewModel(
      configuration: device == null
          ? const DeviceNetworkConfiguration()
          : registry.networkConfiguration(device),
      factory: registry.createManualDevice,
      setups: registry.manualSetups,
      device: widget.device,
    );
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: model.changes, builder: _dialog);
  Widget _dialog(BuildContext context, Widget? child) =>
      DeviceEditorDialog(model: model, onSubmit: _submit, onCancel: _cancel);
  void _submit() {
    final device = model.submit();
    if (device == null) {
      return;
    }
    Navigator.of(context).pop(device);
  }

  void _cancel() => Navigator.of(context).pop();
}
