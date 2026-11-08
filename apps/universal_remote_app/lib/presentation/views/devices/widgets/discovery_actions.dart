import 'package:flutter/material.dart';

import '../viewmodels/devices_viewmodel.dart';

class DiscoveryActions extends StatelessWidget {
  const DiscoveryActions({super.key, required this.model});
  final DevicesViewModel model;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 16,
    runSpacing: 8,
    children: [
      TextButton.icon(
        onPressed: () => model.search(context),
        icon: const Icon(Icons.radar, size: 18),
        label: const Text('Find Nearby Devices'),
      ),
      TextButton(
        onPressed: () => model.add(context),
        child: const Text('Connect by IP'),
      ),
    ],
  );
}
