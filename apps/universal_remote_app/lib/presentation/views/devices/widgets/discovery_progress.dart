import 'package:flutter/material.dart';

class DiscoveryProgress extends StatelessWidget {
  const DiscoveryProgress({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Chip(
      shape: const StadiumBorder(),
      avatar: Icon(
        Icons.circle,
        color: Theme.of(context).colorScheme.primary,
        size: 10,
      ),
      label: const Text('Searching for nearby devices…'),
    ),
  );
}
