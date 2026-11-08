import 'package:flutter/material.dart';

import '../viewmodels/device_editor_viewmodel.dart';

class AdvancedConnectionFields extends StatelessWidget {
  const AdvancedConnectionFields({super.key, required this.model});
  final DeviceEditorViewModel model;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: const Text('Certificate and network wake'),
    children: [
      const Text(
        'For a self-signed TV certificate, verify and provision its exact base64 DER certificate outside this connection. No trust-all mode is used.',
      ),
      const SizedBox(height: 12),
      _certificate(),
      const SizedBox(height: 12),
      _mac(),
      const SizedBox(height: 12),
      _broadcast(),
    ],
  );
  Widget _certificate() => TextField(
    controller: model.certificate,
    minLines: 2,
    maxLines: 4,
    autocorrect: false,
    decoration: const InputDecoration(
      labelText: 'Pinned certificate (base64 DER)',
    ),
  );
  Widget _mac() => TextField(
    controller: model.mac,
    decoration: const InputDecoration(labelText: 'TV MAC address (optional)'),
  );
  Widget _broadcast() => TextField(
    controller: model.broadcast,
    decoration: const InputDecoration(
      labelText: 'Wake broadcast (optional)',
      hintText: '255.255.255.255',
    ),
  );
}
