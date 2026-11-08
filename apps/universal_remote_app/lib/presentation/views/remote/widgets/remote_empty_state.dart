import 'package:flutter/material.dart';

class RemoteEmptyState extends StatelessWidget {
  const RemoteEmptyState({super.key, required this.onChooseDevice});
  final VoidCallback onChooseDevice;
  @override
  Widget build(BuildContext context) => Center(child: _content(context));
  Widget _content(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.settings_remote_outlined, size: 72),
      const SizedBox(height: 20),
      Text(
        'Make yourself comfortable.',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      FilledButton(onPressed: onChooseDevice, child: const Text('Choose a TV')),
    ],
  );
}
