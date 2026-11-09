import 'package:flutter/material.dart';

import '../viewmodels/devices_viewmodel.dart';

class DiscoveryActions extends StatelessWidget {
  const DiscoveryActions({super.key, required this.model});

  final DevicesViewModel model;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    children: [
      _action(
        label: 'Nearby',
        tooltip: 'Find Nearby Devices',
        icon: Icons.radar,
        onPressed: () => model.search(context),
      ),
      _action(
        label: 'IP',
        tooltip: 'Connect by IP',
        icon: Icons.add,
        onPressed: () => model.add(context),
      ),
    ],
  );

  Widget _action({
    required String label,
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
