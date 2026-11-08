import 'package:flutter/material.dart';

import 'package:remote_ui/remote_ui.dart';

import 'device_rename_sheet.dart';

class DeviceRenameState extends State<DeviceRenameSheet> {
  late final name = TextEditingController(text: widget.name);
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AppSheet(title: 'Rename TV', child: _form());
  Widget _form() => Form(
    key: form,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _field(),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: const Text('Save name')),
      ],
    ),
  );
  Widget _field() => TextFormField(
    controller: name,
    autofocus: true,
    decoration: const InputDecoration(labelText: 'TV name'),
    validator: _validate,
    onFieldSubmitted: (_) => _save(),
  );
  String? _validate(String? value) =>
      value == null || value.trim().isEmpty ? 'Enter a name.' : null;
  void _save() {
    if (form.currentState!.validate()) {
      Navigator.pop(context, name.text.trim());
    }
  }
}
