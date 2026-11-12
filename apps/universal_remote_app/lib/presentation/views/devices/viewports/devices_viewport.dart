import 'package:flutter/material.dart';

import '../../../widgets/layout/content_page.dart';
import '../../../widgets/layout/page_title.dart';
import '../viewmodels/devices_viewmodel.dart';
import '../widgets/device_list_section.dart';

class DevicesViewport extends StatelessWidget {
  const DevicesViewport({super.key, required this.model});

  final DevicesViewModel model;

  static const _maxWidth = 640.0;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(child: _devices()),
      _connectButton(context),
    ],
  );

  Widget _devices() => ContentPage(
    maxWidth: _maxWidth,
    padding: const EdgeInsets.symmetric(vertical: 16),
    children: [
      const Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: PageTitle(title: 'Devices'),
      ),
      DeviceListSection(model: model),
    ],
  );

  Widget _connectButton(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: _maxWidth),
    alignment: AlignmentDirectional.centerEnd,
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
    child: FilledButton.icon(
      onPressed: () => model.search(context),
      icon: const Icon(Icons.add),
      label: const Text('Connect'),
    ),
  );
}
