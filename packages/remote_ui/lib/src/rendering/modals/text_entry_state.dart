import 'package:flutter/material.dart';

import '../../widgets/sheets/app_sheet.dart';
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
      children: [
        const Text('Select a text field on the TV first. Text is not logged.'),
        const SizedBox(height: 16),
        TextField(
          controller: text,
          maxLength: 2048,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Text'),
        ),
        FilledButton(
          onPressed: () {
            if (text.text.isNotEmpty) {
              Navigator.pop(context, text.text);
            }
          },
          child: const Text('Send'),
        ),
      ],
    ),
  );
}
