import 'package:flutter/material.dart';

import '../../../widgets/layout/content_page.dart';
import '../viewmodels/devices_viewmodel.dart';
import '../widgets/discovery_actions.dart';
import '../widgets/device_list_section.dart';

class DevicesViewport extends StatelessWidget {
  const DevicesViewport({super.key, required this.model});
  final DevicesViewModel model;
  @override
  Widget build(BuildContext context) => ContentPage(
    maxWidth: 640,
    children: [
      _header(context),
      const SizedBox(height: 20),
      DeviceListSection(model: model, devices: model.saved, saved: true),
      const SizedBox(height: 24),
      DiscoveryActions(model: model),
    ],
  );
  Widget _header(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text('Devices', style: Theme.of(context).textTheme.titleLarge),
      ),
    ],
  );
}
