import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

class StructuredInputEditor extends StatelessWidget {
  const StructuredInputEditor({
    super.key,
    required this.kind,
    required this.touchpad,
    required this.keyboard,
    required this.onTouchpad,
    required this.onKeyboard,
  });

  final GridWidgetKind kind;
  final TouchpadConfiguration touchpad;
  final KeyboardConfiguration keyboard;
  final ValueChanged<TouchpadConfiguration> onTouchpad;
  final ValueChanged<KeyboardConfiguration> onKeyboard;

  @override
  Widget build(BuildContext context) => switch (kind) {
    GridWidgetKind.touchpad => _touchpad(),
    GridWidgetKind.keyboard => SwitchListTile(
      title: const Text('Submit after sending text'),
      value: keyboard.submitAfterTyping,
      onChanged: (value) =>
          onKeyboard(KeyboardConfiguration(submitAfterTyping: value)),
    ),
    _ => const SizedBox.shrink(),
  };

  Widget _touchpad() => Column(
    children: [
      const Text('Pointer sensitivity'),
      Slider(
        value: touchpad.sensitivity,
        min: .5,
        max: 2,
        divisions: 6,
        label: touchpad.sensitivity.toStringAsFixed(2),
        onChanged: (value) => onTouchpad(
          TouchpadConfiguration(sensitivity: value, scroll: touchpad.scroll),
        ),
      ),
      SwitchListTile(
        title: const Text('Two-finger scrolling'),
        value: touchpad.scroll,
        onChanged: (value) => onTouchpad(
          TouchpadConfiguration(
            sensitivity: touchpad.sensitivity,
            scroll: value,
          ),
        ),
      ),
    ],
  );
}
