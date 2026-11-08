import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import 'action_button_state.dart';

class ActionButton extends StatefulWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.iconWidget,
    this.elementStyle,
    this.unavailableReason,
    this.showLabel = true,
    this.repeat = false,
    this.appearance = const {},
  });
  final String label;
  final IconData icon;
  final Widget? iconWidget;
  final RemoteElementStyle? elementStyle;
  final String? unavailableReason;
  final VoidCallback? onPressed;
  final bool showLabel, repeat;
  final Map<String, String> appearance;
  @override
  State<ActionButton> createState() => ActionButtonState();
}
