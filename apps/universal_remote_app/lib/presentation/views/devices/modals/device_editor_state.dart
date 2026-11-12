import 'package:flutter/material.dart';

import '../viewmodels/device_editor_viewmodel.dart';
import 'device_editor.dart';
import 'device_editor_dialog.dart';

class DeviceEditorState extends State<DeviceEditor> {
  late final DeviceEditorViewModel model;
  @override
  void initState() {
    super.initState();
    model = DeviceEditorViewModel.forApp(
      widget.dependencies,
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
  Future<void> _submit() async {
    final device = await model.submit();
    if (!mounted || device == null) {
      return;
    }
    Navigator.of(context).pop(device);
  }

  void _cancel() => Navigator.of(context).pop();
}
