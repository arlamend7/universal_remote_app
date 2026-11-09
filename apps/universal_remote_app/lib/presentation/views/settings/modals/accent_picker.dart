import 'package:flutter/material.dart';

import 'accent_picker_state.dart';

class AccentPicker extends StatefulWidget {
  const AccentPicker({super.key, required this.initialValue});

  final int initialValue;

  @override
  State<AccentPicker> createState() => AccentPickerState();
}
