import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/remote_ui.dart';

import '../../devices/widgets/discovery_progress.dart';
import '../viewmodels/discovery_viewmodel.dart';
import 'device_discovery_sheet.dart';

class DeviceDiscoveryState extends State<DeviceDiscoverySheet> {
  late final model = DiscoveryViewModel(widget.dependencies);
  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    await widget.dependencies.discovery.stop();
    if (mounted) {
      await model.search();
    }
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppSheet(
    title: 'Find Nearby Devices',
    child: ListenableBuilder(listenable: model, builder: _body),
  );
  Widget _body(BuildContext context, Widget? child) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (model.searching) const DiscoveryProgress(),
      if (model.error != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(model.error!, semanticsLabel: model.error),
        ),
      if (!model.searching && model.fresh.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No new devices found. Keep your TV on and connected to the same network.',
          ),
        ),
      ...model.fresh.map(_newDevice),
      if (model.known.isNotEmpty) _registered(),
      const SizedBox(height: 16),
      TextButton.icon(
        onPressed: model.adding
            ? null
            : model.searching
            ? model.cancel
            : model.search,
        icon: Icon(model.searching ? Icons.close : Icons.refresh),
        label: Text(model.searching ? 'Cancel search' : 'Search again'),
      ),
    ],
  );
  Widget _newDevice(RemoteDevice device) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.tv_outlined),
    title: Text(device.name),
    subtitle: Text(device.endpoints.firstOrNull?.host ?? 'Nearby device'),
    trailing: TextButton(
      onPressed: model.adding ? null : () => _add(device),
      child: const Text('Add'),
    ),
  );
  Widget _registered() => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: Text('Already added (${model.known.length})'),
    children: model.known.map(_knownDevice).toList(),
  );
  Widget _knownDevice(RemoteDevice device) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.check),
    title: Text(model.registered(device)!.name),
    subtitle: Text('Registered · ${device.endpoints.firstOrNull?.host ?? ''}'),
    trailing: TextButton(
      onPressed: model.adding ? null : () => model.updateAddress(device),
      child: const Text('Update address'),
    ),
  );
  Future<void> _add(RemoteDevice device) async {
    final selected = await model.add(device);
    if (selected != null && mounted) {
      Navigator.pop(context, selected);
    }
  }
}
