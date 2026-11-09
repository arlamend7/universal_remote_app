import 'package:flutter/material.dart';

import '../sheets/app_sheet.dart';
import '../sheets/app_sheet_actions.dart';
import '../sheets/show_app_sheet.dart';

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.message,
  });
  final String title;
  final String confirmLabel;
  final String? message;
  static Future<bool> ask(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    String? message,
  }) async {
    final confirmed = await showAppModal<bool>(
      context,
      builder: (_) => ConfirmationDialog(
        title: title,
        confirmLabel: confirmLabel,
        message: message,
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) => AppSheet(
    title: title,
    child: message == null ? const SizedBox.shrink() : Text(message!),
    footer: _actions(context),
  );

  Widget _actions(BuildContext context) => AppSheetActions(
    secondary: OutlinedButton(
      onPressed: () => Navigator.pop(context, false),
      child: const Text('Cancel'),
    ),
    primary: FilledButton(
      onPressed: () => Navigator.pop(context, true),
      child: Text(confirmLabel),
    ),
  );
}
