import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/remote_ui.dart';

import '../../devices/widgets/discovery_progress.dart';
import '../../devices/modals/edit_device.dart';
import '../../../../domains/discovery/models/connection_issue_type.dart';
import '../widgets/discovery_details.dart';
import '../widgets/discovery_issue.dart';
import '../viewmodels/discovery_viewmodel.dart';
import 'device_discovery_sheet.dart';

class DeviceDiscoveryState extends State<DeviceDiscoverySheet> {
  bool _detailsVisible = false;
  bool _offlineDismissed = false;
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
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: model, builder: _sheet);

  Widget _sheet(BuildContext context, Widget? child) => AppSheet(
    title: 'Find Nearby Devices',
    subtitle: model.searching ? 'Scanning…' : null,
    child: _body(),
    footer: _footer(),
  );

  Widget _body() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (model.searching)
        DiscoveryProgress(protocols: model.searchingProtocols),
      if (widget.dependencies.discovery.issue.value case final issue?)
        DiscoveryIssue(
          type: issue,
          retry: _search,
          dismiss: () => Navigator.pop(context),
        )
      else if (model.error != null)
        _message(Icons.info_outline, model.error!),
      if (widget.dependencies.discovery.catalogOffline.value &&
          !_offlineDismissed)
        DiscoveryIssue(
          type: ConnectionIssueType.internetUnavailable,
          retry: widget.dependencies.discovery.refreshCatalog,
          dismiss: () => setState(() => _offlineDismissed = true),
        ),
      if (!model.searching && model.cancelled)
        _message(Icons.pause_circle_outline, 'Search cancelled.'),
      if (_showEmpty) _empty(),
      if (model.unresolvedCount > 0)
        _message(
          Icons.help_outline,
          '${model.unresolvedCount} unrecognized discovery responses',
        ),
      if (model.fresh.isNotEmpty) _resultsHeading(),
      ...model.fresh.map(_newDevice),
      if (model.known.isNotEmpty) _registered(),
      if (model.fresh.isNotEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Text(
            'Make sure your TV is on and on the same Wi-Fi.',
            textAlign: TextAlign.center,
          ),
        ),
      if (_detailsVisible && model.statuses.isNotEmpty)
        DiscoveryDetails(model: model),
    ],
  );

  bool get _showEmpty =>
      !model.searching &&
      !model.cancelled &&
      model.error == null &&
      model.found.isEmpty &&
      model.unresolvedCount == 0;

  Widget _footer() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _actions(),
      if (model.statuses.isNotEmpty)
        Center(
          child: TextButton(
            onPressed: () => setState(() => _detailsVisible = !_detailsVisible),
            child: Text(
              _detailsVisible ? 'Hide search details' : 'Search details',
              style: const TextStyle(decoration: TextDecoration.underline),
            ),
          ),
        ),
    ],
  );

  Future<void> _search() {
    setState(() => _offlineDismissed = false);
    return model.search();
  }

  Widget _actions() => AppSheetActions(
    secondary: OutlinedButton.icon(
      onPressed: model.adding ? null : _connectByIp,
      icon: const Icon(Icons.link, size: 18),
      label: const Text('Connect by IP'),
    ),
    primary: FilledButton.icon(
      onPressed: model.adding
          ? null
          : model.searching
          ? model.cancel
          : _search,
      icon: Icon(model.searching ? Icons.close : Icons.refresh, size: 18),
      label: Text(model.searching ? 'Cancel search' : 'Search again'),
    ),
  );

  Widget _empty() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 26),
    child: Column(
      children: [
        CircleAvatar(
          radius: 38,
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: const Icon(Icons.tv_off_outlined, size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          'No Displays Found',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Keep your TV on and connected to the same Wi-Fi network.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _message(IconData icon, String text) => Card(
    child: ListTile(leading: Icon(icon), title: Text(text)),
  );

  Widget _resultsHeading() => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 8,
      children: [
        const Text('Discovered Displays'),
        Text('${model.fresh.length} found'),
      ],
    ),
  );

  Widget _newDevice(RemoteDevice device) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Card(
      child: ListTile(
        leading: _displayIcon(),
        title: Text(device.name),
        subtitle: const Text('•  Nearby'),
        trailing: FilledButton.tonal(
          onPressed: model.adding ? null : () => _add(device),
          child: const Text('Connect'),
        ),
      ),
    ),
  );

  Widget _displayIcon() => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Icon(
      Icons.tv_outlined,
      color: Theme.of(context).colorScheme.primary,
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
  Future<void> _connectByIp() async {
    final device = await editDevice(context, widget.dependencies);
    if (mounted && device != null) {
      Navigator.pop(context, device);
    }
  }

  Future<void> _add(RemoteDevice device) async {
    final selected = await model.add(device);
    if (selected != null && mounted) {
      Navigator.pop(context, selected);
    }
  }
}
