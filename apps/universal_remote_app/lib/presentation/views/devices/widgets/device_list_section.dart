import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../viewmodels/devices_viewmodel.dart';
import 'device_tile.dart';

class DeviceListSection extends StatelessWidget {
  const DeviceListSection({
    super.key,
    required this.model,
    required this.devices,
    required this.saved,
  });
  final DevicesViewModel model;
  final List<RemoteDevice> devices;
  final bool saved;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (!saved)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Nearby TVs',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      if (saved && devices.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Text(
            'Your TVs, all in one place.\nFind a nearby TV or connect by IP.',
            textAlign: TextAlign.center,
          ),
        ),
      ...devices.map((device) => DeviceTile(model: model, device: device)),
    ],
  );
}
