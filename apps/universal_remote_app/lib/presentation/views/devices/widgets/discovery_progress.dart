import 'package:flutter/material.dart';

/// A visible status region while discovery is actually running; no fake delay.
class DiscoveryProgress extends StatelessWidget {
  const DiscoveryProgress({super.key});
  @override
  Widget build(BuildContext context) =>
      Semantics(liveRegion: true, child: _content(context));
  Widget _content(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: _status(context),
  );
  Widget _status(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Searching for LG TVs…',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      const LinearProgressIndicator(
        minHeight: 8,
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      const SizedBox(height: 8),
      const Text('Checking your local network. Keep your TV turned on.'),
    ],
  );
}
