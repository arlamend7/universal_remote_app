import 'package:flutter/material.dart';

/// Says a command left for a TV that gives no feedback on its state. Does
/// nothing when the screen that sent it has gone.
void showCommandSent(BuildContext? context) {
  if (context == null || !context.mounted) {
    return;
  }
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    const SnackBar(content: Text('Command sent. Check the TV for a response.')),
  );
}
