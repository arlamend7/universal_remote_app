import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';

class DriverCapabilitiesPage extends StatelessWidget {
  const DriverCapabilitiesPage({super.key, required this.release});

  final DriverRelease release;

  @override
  Widget build(BuildContext context) {
    final manifest = release.manifest;
    return Scaffold(
      appBar: AppBar(title: const Text('Capabilities')),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              title: Text('${manifest.name} ${manifest.identity.version}'),
              subtitle: const Text(
                'Catalog declarations. Live device verification is required.',
              ),
            ),
            ListTile(
              title: const Text('Required driver operations'),
              subtitle: Text(
                manifest.runtime.operations
                    .map((operation) => operation.id)
                    .join(', '),
              ),
            ),
            for (final capability in RemoteCapability.values)
              _capability(manifest, capability),
          ],
        ),
      ),
    );
  }

  Widget _capability(DriverManifest manifest, RemoteCapability capability) {
    final declared = manifest.capabilities.contains(capability);
    final constraints = [
      for (final profile in manifest.compatibility)
        if (profile.models.isNotEmpty || profile.firmwareVersion != null)
          [
            profile.id,
            if (profile.models.isNotEmpty) profile.models.join(', '),
            if (profile.firmwareVersion != null)
              'Firmware ${profile.firmwareVersion}',
          ].join(' · '),
    ];
    return ListTile(
      title: Text(capability.name),
      subtitle: Text(
        [
          if (!declared) 'Unsupported by this release',
          if (declared && constraints.isEmpty) 'Declared by the driver',
          if (declared && constraints.isNotEmpty) ...[
            'Conditional by profile',
            ...constraints,
          ],
          if (declared &&
              manifest.runtime.operations.contains(
                DriverOperation.webSocketPair,
              ))
            'Driver includes a pairing workflow',
        ].join('\n'),
      ),
    );
  }
}
