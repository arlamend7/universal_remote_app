import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../domains/discovery/functions/discovery_diagnostic_fields.dart';
import '../../../../domains/discovery/functions/discovery_failure_message.dart';
import '../viewmodels/discovery_viewmodel.dart';

class DiscoveryDetails extends StatelessWidget {
  const DiscoveryDetails({super.key, required this.model});

  final DiscoveryViewModel model;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ...model.statuses.map((report) => _protocol(context, report)),
      TextButton.icon(
        onPressed: () =>
            Clipboard.setData(ClipboardData(text: model.diagnosticReport)),
        icon: const Icon(Icons.copy),
        label: Text('Copy diagnostics'),
      ),
    ],
  );

  Widget _protocol(BuildContext context, ProtocolDiscoveryStatus report) {
    final fields = discoveryDiagnosticFields(report);
    final code = fields['code'];
    final stage = fields['stage'];
    final osCode = fields['osCode'];
    final operation = osCode == null ? '$stage' : '$stage · OS $osCode';
    final failure = report.failure;
    final status = switch (report.status) {
      DiscoveryStatus.searching => 'Searching',
      DiscoveryStatus.success => '${report.deviceCount} found',
      DiscoveryStatus.partialSuccess =>
        '${report.deviceCount} found before an error',
      DiscoveryStatus.empty => 'No responses matched',
      DiscoveryStatus.failed => 'Search failed',
      DiscoveryStatus.cancelled => 'Cancelled',
    };
    final notes = [
      status,
      if (failure != null) '$code · $operation',
      if (failure != null) discoveryFailureMessage(failure.error),
      if (report.observations.isNotEmpty)
        report.observations.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(' · '),
    ];
    return ListTile(
      title: Text(model.searchLabel(report)),
      subtitle: Text(notes.join('\n')),
    );
  }
}
