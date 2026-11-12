import 'package:flutter/material.dart';

/// States whether the manual connection will be encrypted.
class TransportSecurityNote extends StatelessWidget {
  const TransportSecurityNote({super.key, required this.legacy});

  final bool legacy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = legacy
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        Icon(
          _icon,
          size: 18,
          color: legacy ? color : theme.colorScheme.primary,
        ),
        Flexible(
          child: Text(
            _message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  IconData get _icon =>
      legacy ? Icons.warning_amber_rounded : Icons.verified_user_outlined;

  String get _message => legacy
      ? 'Unencrypted legacy connection. Use only on a trusted network.'
      : 'Encrypted connection over local Wi-Fi';
}
