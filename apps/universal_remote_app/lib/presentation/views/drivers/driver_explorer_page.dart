import 'package:flutter/material.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';

import 'driver_versions_page.dart';

class DriverExplorerPage extends StatelessWidget {
  DriverExplorerPage({
    super.key,
    DriverCatalogRepository? catalogs,
    this.inventory = const {},
  }) : _metadata = _load(catalogs);

  final Future<(DriverCatalog?, DateTime?)> _metadata;
  final Map<String, DriverInstallation> inventory;

  static Future<(DriverCatalog?, DateTime?)> _load(
    DriverCatalogRepository? catalogs,
  ) async => (await catalogs?.cached(), await catalogs?.lastChecked());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Drivers')),
    body: SafeArea(
      child: FutureBuilder(future: _metadata, builder: _body),
    ),
  );

  Widget _body(
    BuildContext context,
    AsyncSnapshot<(DriverCatalog?, DateTime?)> snapshot,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    final (catalog, checkedAt) = snapshot.data ?? (null, null);
    final providers = <String, List<DriverRelease>>{};
    for (final release in catalog?.releases ?? const <DriverRelease>[]) {
      if (!release.development &&
          release.manifest.identity.providerId != 'roku.ecp') {
        providers
            .putIfAbsent(release.manifest.identity.providerId, () => [])
            .add(release);
      }
    }
    if (providers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            snapshot.hasError
                ? 'The saved driver catalog could not be verified.'
                : 'No verified driver catalog is available.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(
      children: [
        if (checkedAt != null)
          ListTile(
            title: const Text('Last catalog refresh'),
            subtitle: Text(
              MaterialLocalizations.of(context)
                  .formatMediumDate(checkedAt.toLocal()),
            ),
          ),
        for (final releases in providers.values) _provider(context, releases),
      ],
    );
  }

  Widget _provider(BuildContext context, List<DriverRelease> releases) {
    releases.sort(
      (a, b) =>
          b.manifest.identity.version.compareTo(a.manifest.identity.version),
    );
    final latest = releases.first.manifest;
    final installed = releases.where((release) => _installed(release)).length;
    final compatible = releases.any(
      (release) => DriverManager.supportsManifest(release.manifest),
    );
    return ListTile(
      title: Text(latest.name),
      subtitle: Text(
        '${latest.platform} · ${releases.length} published · $installed installed\n'
        'Latest ${latest.identity.version} · ${compatible ? 'Runtime compatible' : 'App update required'}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DriverVersionsPage(
            name: latest.name,
            releases: releases,
            inventory: inventory,
          ),
        ),
      ),
    );
  }

  bool _installed(DriverRelease release) {
    final id = release.manifest.identity;
    final record = inventory[id.id];
    return record?.active == id.version || record?.previous == id.version;
  }
}
