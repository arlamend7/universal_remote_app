import 'package:flutter/material.dart';

import 'device_choice_state.dart';

class DeviceChoiceSheet extends StatefulWidget {
  const DeviceChoiceSheet({
    super.key,
    required this.title,
    required this.choices,
    this.selectedId,
  });
  final String title;
  final List<(String, String)> choices;
  final String? selectedId;
  static Future<String?> choose(
    BuildContext context,
    String title,
    List<(String, String)> choices, {
    String? selectedId,
  }) => showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (_) => DeviceChoiceSheet(
      title: title,
      choices: choices,
      selectedId: selectedId,
    ),
  );
  @override
  State<DeviceChoiceSheet> createState() => DeviceChoiceState();
}
