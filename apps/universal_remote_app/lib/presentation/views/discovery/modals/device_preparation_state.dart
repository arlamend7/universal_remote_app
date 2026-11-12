import 'package:flutter/material.dart';

import 'device_preparation_sheet.dart';

class DevicePreparationState extends State<DevicePreparationSheet> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) => preparationContent(
    context,
    confirmed: _confirmed,
    onConfirm: (value) => setState(() => _confirmed = value ?? false),
  );
}
