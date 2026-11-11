import 'package:flutter/material.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';

import 'driver_capabilities_page.dart';
import 'driver_profile_summary.dart';

class DriverVersionsPage extends StatelessWidget {
  const DriverVersionsPage({
    super.key,
    required this.name,
    required this.releases,
    required this.inventory,
  });

  final String name;
  final List<DriverRelease> releases;
  final Map<String, DriverInstallation> inventory;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(name)),
    body: SafeArea(
      child: ListView(
        children: [
          const ListTile(title: Text('Versions')),
          for (final release in releases) _version(context, release),
        ],
      ),
    ),
  );

  Widget _version(BuildContext context, DriverRelease release) {
    final manifest = release.manifest;
    final id = manifest.identity;
    final record = inventory[id.id];
    final status = record?.active == id.version
        ? (record!.enabled ? 'Installed and active' : 'Installed and disabled')
        : (record?.previous == id.version
              ? 'Installed for rollback'
              : 'Available');
    final published = release.publishedAt;
    return ListTile(
      title: Text(id.version.toString()),
      subtitle: Text(
        [
          status,
          'Runtime ${manifest.runtime.constraint}',
          DriverManager.supportsManifest(manifest)
              ? 'Runtime compatible'
              : 'App update required',
          if (published != null)
            MaterialLocalizations.of(context).formatMediumDate(published),
          ...manifest.compatibility.map(driverProfileSummary),
          if (release.notes?.isNotEmpty == true) release.notes!,
        ].join('\n'),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DriverCapabilitiesPage(release: release),
        ),
      ),
    );
  }
}
