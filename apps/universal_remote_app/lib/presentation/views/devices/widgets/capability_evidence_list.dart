import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

class CapabilityEvidenceList extends StatelessWidget {
  const CapabilityEvidenceList({super.key, required this.evidence});
  final List<CapabilityEvidence> evidence;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Capability checks', style: Theme.of(context).textTheme.titleMedium),
      ...evidence.map(_tile),
    ],
  );
  Widget _tile(CapabilityEvidence item) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(item.capability.name),
    subtitle: Text(_description(item)),
  );
  String _description(CapabilityEvidence item) {
    final status = switch (item.availability) {
      CapabilityAvailability.advertised => 'Declared',
      CapabilityAvailability.known => 'Known supported',
      CapabilityAvailability.verified => 'Device verified',
      CapabilityAvailability.conditional => 'Conditional',
      CapabilityAvailability.unavailable => 'Temporarily unavailable',
      CapabilityAvailability.unsupported => 'Unsupported',
      CapabilityAvailability.unknown => 'Unknown',
    };
    final state = '${item.source.name} · $status';
    if (item.reason == null) {
      return state;
    }
    return '$state\n${item.reason}';
  }
}
