import 'package:flutter/material.dart';

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: title,
        confirmLabel: confirmLabel,
        message: message,
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: message == null ? null : Text(message!),
    actions: _actions(context),
  );
  List<Widget> _actions(BuildContext context) => [
    TextButton(
      onPressed: () => Navigator.pop(context, false),
      child: const Text('Cancel'),
    ),
    FilledButton(
      onPressed: () => Navigator.pop(context, true),
      child: Text(confirmLabel),
    ),
  ];
}
