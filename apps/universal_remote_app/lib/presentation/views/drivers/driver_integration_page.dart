import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'models/driver_integration_summary.dart';
import 'widgets/driver_detail_row.dart';

/// One integration: compatibility, update state and declared capabilities.
class DriverIntegrationPage extends StatelessWidget {
  const DriverIntegrationPage({super.key, required this.integration});

  final DriverIntegrationSummary integration;

  @override
  Widget build(BuildContext context) {
    final entry = integration.entry;
    final compatibility = entry.compatibility;
    final localizations = MaterialLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(entry.name)),
      body: SafeArea(
        child: ListView(
          children: [
            DriverDetailRow('Provider', entry.providerId),
            DriverDetailRow('Integration', entry.id),
            DriverDetailRow('Platform', entry.platform),
            DriverDetailRow(
              'Supported OS',
              compatibility.osVersion?.expression ?? 'All versions',
            ),
            DriverDetailRow(
              'Supported firmware',
              compatibility.firmwareVersion?.expression ?? 'All versions',
            ),
            DriverDetailRow(
              'Supported models',
              compatibility.models.isEmpty
                  ? 'All models'
                  : compatibility.models.join(', '),
            ),
            DriverDetailRow(
              'Last update',
              localizations.formatMediumDate(entry.lastUpdatedAt.toLocal()),
            ),
            DriverDetailRow(
              'Installed package',
              integration.installedHash?.substring(0, 12) ?? 'Not installed',
            ),
            DriverDetailRow(
              'Update',
              integration.updateAvailable
                  ? 'A newer verified package is published.'
                  : 'Up to date or not installed',
            ),
            DriverDetailRow(
              'Required runtime',
              'API ${entry.runtime.api} · ${entry.runtime.operations.join(', ')}',
            ),
            DriverDetailRow(
              'Compatibility profiles',
              [
                for (final profile in entry.profiles)
                  '${profile.id} (${profile.stage.id}'
                      '${profile.compatibility.osVersion == null ? '' : ', OS ${profile.compatibility.osVersion}'}'
                      '${profile.compatibility.firmwareVersion == null ? '' : ', firmware ${profile.compatibility.firmwareVersion}'})',
              ].join('\n'),
            ),
            const ListTile(title: Text('Capabilities')),
            for (final capability in entry.capabilities)
              _capability(capability),
          ],
        ),
      ),
    );
  }

  Widget _capability(RemoteCapability capability) {
    final conditional = integration.entry.conditionalCapabilities.contains(
      capability,
    );
    final disabled = [
      for (final profile in integration.entry.profiles)
        if (profile.disabledCapabilities.contains(capability)) profile.id,
    ];
    return ListTile(
      dense: true,
      title: Text(capability.name),
      subtitle: Text(
        [
          conditional
              ? 'Conditional: verified on the connected TV'
              : 'Declared by the integration',
          if (disabled.isNotEmpty) 'Disabled by ${disabled.join(', ')}',
        ].join(' · '),
      ),
    );
  }
}
