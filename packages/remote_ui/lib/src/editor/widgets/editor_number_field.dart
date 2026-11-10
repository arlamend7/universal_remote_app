import 'package:flutter/material.dart';

import 'editor_number_field_state.dart';

class EditorNumberField extends StatefulWidget {
  const EditorNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
  }) : isRotation = false;

  const EditorNumberField.rotation({
    super.key,
    required this.value,
    required this.onChanged,
  }) : label = 'Rotate',
       minimum = 0,
       maximum = 3,
       isRotation = true;

  final bool isRotation;
  final String label;
  final int value, minimum, maximum;
  final ValueChanged<int> onChanged;

  @override
  State<EditorNumberField> createState() => EditorNumberFieldState();
}
