import 'package:flutter/material.dart';

import '../../widgets/sheets/app_sheet.dart';
import '../../widgets/sheets/app_sheet_actions.dart';
import 'text_entry_sheet.dart';

class TextEntryState extends State<TextEntrySheet> {
  final text = TextEditingController();
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppSheet(
    title: 'Send text to TV',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        const Text('Select a text field on the TV first. Text is not logged.'),
        TextField(
          controller: text,
          maxLength: 2048,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Text'),
        ),
      ],
    ),
    footer: AppSheetActions(
      primary: FilledButton(onPressed: _send, child: const Text('Send')),
    ),
  );

  void _send() {
    if (text.text.isNotEmpty) {
      Navigator.pop(context, text.text);
    }
  }
}
