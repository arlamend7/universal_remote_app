import 'package:flutter/material.dart';

import 'driver_integration_page.dart';
import 'models/driver_integration_summary.dart';
import 'models/driver_provider_summary.dart';

/// The integrations (compatibility families) of one provider.
class DriverProviderPage extends StatelessWidget {
  const DriverProviderPage({super.key, required this.provider});

  final DriverProviderSummary provider;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(provider.name)),
    body: SafeArea(
      child: ListView(
        children: [
          const ListTile(title: Text('Integrations')),
          for (final integration in provider.integrations)
            _integration(context, integration),
        ],
      ),
    ),
  );

  Widget _integration(
    BuildContext context,
    DriverIntegrationSummary integration,
  ) {
    final entry = integration.entry;
    final state = integration.updateAvailable
        ? 'Update available'
        : integration.isInstalled
        ? 'Installed'
        : 'Not installed';
    return ListTile(
      title: Text(entry.name),
      subtitle: Text(
        '${entry.compatibility.osVersion?.expression ?? 'All OS versions'} · '
        'Updated ${MaterialLocalizations.of(context).formatMediumDate(entry.lastUpdatedAt.toLocal())} · '
        '$state',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DriverIntegrationPage(integration: integration),
        ),
      ),
    );
  }
}
