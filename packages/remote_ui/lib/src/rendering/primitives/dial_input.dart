import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_remote_viewmodel.dart';
import 'dial_input_state.dart';

class DialInput extends StatefulWidget {
  const DialInput({super.key, required this.item, required this.model});
  final GridItem item;
  final GridRemoteViewModel model;

  @override
  State<DialInput> createState() => DialInputState();
}
