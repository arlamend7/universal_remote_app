import 'package:flutter/material.dart';

import '../sheets/app_sheet.dart';
import 'device_choice_sheet.dart';
import 'choice_items.dart';

class DeviceChoiceState extends State<DeviceChoiceSheet> {
  String query = '';
  bool get apps => widget.title == 'Apps';
  @override
  Widget build(BuildContext context) =>
      AppSheet(title: widget.title, child: _content());
  Widget _content() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (apps && widget.choices.length > 6)
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search apps',
          ),
          onChanged: (value) => setState(() => query = value),
        ),
      if (apps) const SizedBox(height: 16),
      ChoiceItems(
        choices: widget.choices
            .where(
              (choice) => choice.$2.toLowerCase().contains(query.toLowerCase()),
            )
            .toList(),
        grid: apps,
        selectedId: widget.selectedId,
      ),
    ],
  );
}
