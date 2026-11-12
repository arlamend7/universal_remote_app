import 'package:flutter/material.dart';

import '../../../shared/localization/journey_text.dart';

class DiscoveryProgress extends StatelessWidget {
  const DiscoveryProgress({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          Text(
            journeyText(
              context,
              'Searching for nearby devices…',
              'Buscando dispositivos próximos…',
            ),
          ),
          const LinearProgressIndicator(minHeight: 3),
        ],
      ),
    ),
  );
}
