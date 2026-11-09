import 'package:flutter/material.dart';

import '../../../widgets/layout/content_page.dart';
import '../viewmodels/devices_viewmodel.dart';
import '../widgets/device_list_section.dart';
import '../widgets/discovery_actions.dart';

class DevicesViewport extends StatelessWidget {
  const DevicesViewport({super.key, required this.model});

  final DevicesViewModel model;

  @override
  Widget build(BuildContext context) => ContentPage(
    maxWidth: 640,
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    children: [
      _header(context),
      const SizedBox(height: 18),
      DeviceListSection(model: model),
    ],
  );

  Widget _header(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 12,
    runSpacing: 4,
    children: [
      Text(
        'Devices',
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -.6),
      ),
      DiscoveryActions(model: model),
    ],
  );
}
