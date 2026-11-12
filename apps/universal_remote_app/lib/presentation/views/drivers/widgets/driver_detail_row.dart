import 'package:flutter/material.dart';

/// One label/value line in the Driver Explorer.
class DriverDetailRow extends StatelessWidget {
  const DriverDetailRow(this.label, this.value, {super.key});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    title: Text(label),
    subtitle: Text(value == null || value!.isEmpty ? 'Not declared' : value!),
  );
}
