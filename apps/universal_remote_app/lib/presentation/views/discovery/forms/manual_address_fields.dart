import 'package:flutter/material.dart';

import '../../devices/forms/platform_field.dart';
import '../../devices/viewmodels/device_editor_viewmodel.dart';
import '../widgets/address_ready_indicator.dart';
import '../widgets/transport_security_note.dart';

class ManualAddressFields extends StatelessWidget {
  const ManualAddressFields({
    super.key,
    required this.model,
    required this.onSubmitted,
  });

  final DeviceEditorViewModel model;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 20,
    children: [
      if (model.showsPlatformChoice) PlatformField(model: model),
      ValueListenableBuilder(valueListenable: model.address, builder: _address),
      TransportSecurityNote(legacy: model.legacy.value),
      if (model.error.value case final message?) _error(context, message),
    ],
  );

  Widget _address(BuildContext context, TextEditingValue value, Widget? _) {
    final theme = Theme.of(context);
    return TextField(
      controller: model.address,
      enabled: !model.checking.value,
      autocorrect: false,
      textInputAction: TextInputAction.go,
      onSubmitted: (_) => onSubmitted(),
      style: theme.textTheme.titleLarge?.copyWith(
        color: theme.colorScheme.primary,
        fontFamily: 'monospace',
        fontFamilyFallback: const ['Menlo', 'Courier New'],
        letterSpacing: 1,
      ),
      decoration: InputDecoration(
        labelText: 'TV IP address',
        hintText: '192.168.1.100',
        suffixIcon: model.addressIsValid ? const AddressReadyIndicator() : null,
      ),
    );
  }

  Widget _error(BuildContext context, String message) => Text(
    message,
    textAlign: TextAlign.center,
    style: TextStyle(color: Theme.of(context).colorScheme.error),
  );
}
