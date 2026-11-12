import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/remote_ui.dart';

import '../../devices/widgets/discovery_progress.dart';
import '../../devices/modals/edit_device.dart';
import '../../pairing/modals/show_device_pairing.dart';
import '../../../../domains/discovery/models/connection_issue_type.dart';
import '../widgets/discovery_details.dart';
import '../widgets/discovery_issue.dart';
import '../widgets/discovered_device_tile.dart';
import '../viewmodels/discovery_viewmodel.dart';
import 'device_discovery_sheet.dart';

class DeviceDiscoveryState extends State<DeviceDiscoverySheet> {
  String? _selectedId;

  RemoteDevice? get _selected =>
      model.found.where((device) => device.id == _selectedId).firstOrNull;
  List<RemoteDevice> get _selectable => model.found
      .where(
        (device) =>
            device.id == _selectedId || model.registered(device) == null,
      )
      .toList();
  List<RemoteDevice> get _registeredResults =>
      model.known.where((device) => device.id != _selectedId).toList();
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

  Widget _sheet(BuildContext context, Widget? child) =>
      AppSheet(title: 'Find Nearby Devices', child: _body(), footer: _footer());

  Widget _body() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (model.searching) const DiscoveryProgress(),
      if (_connectionIssue() case final issue?) issue,
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
      if (_selectable.isNotEmpty) _resultsHeading(),
      ..._selectable.map(_newDevice),
      if (_registeredResults.isNotEmpty) _registered(),
      if (_selectable.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            'Keep your TV on and on the same local network.',
            textAlign: TextAlign.center,
          ),
        ),
      if (model.statuses.isNotEmpty)
        ExpansionTile(
          key: ValueKey(widget.dependencies.discovery.searchId),
          tilePadding: EdgeInsets.zero,
          title: Text('Search details'),
          children: [DiscoveryDetails(model: model)],
        ),
    ],
  );

  Widget? _connectionIssue() {
    final issue = widget.dependencies.discovery.issue.value;
    if (issue != null) {
      return DiscoveryIssue(
        type: issue,
        retry: _search,
        dismiss: () => Navigator.pop(context),
      );
    }
    final error = model.error;
    return error == null ? null : _message(Icons.info_outline, error);
  }

  bool get _showEmpty =>
      !model.searching &&
      !model.cancelled &&
      model.error == null &&
      model.found.isEmpty;

  Widget _footer() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 8,
    children: [
      if (_selectable.isNotEmpty)
        FilledButton(
          onPressed: _selected == null || model.adding ? null : _connect,
          child: Text('Connect'),
        ),
      _actions(),
    ],
  );

  Future<void> _search() {
    setState(() {
      _offlineDismissed = false;
      _selectedId = null;
    });
    return model.search();
  }

  Widget _actions() => AppSheetActions(
    secondary: OutlinedButton.icon(
      onPressed: model.adding ? null : _connectByIp,
      icon: const Icon(Icons.link, size: 18),
      label: Text('Connect by IP'),
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
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      spacing: 8,
      children: [
        Icon(
          Icons.tv_off_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        Text(
          'No Displays Found',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          'Check that your TV is on and reachable on the local network.',
          textAlign: TextAlign.center,
        ),
        TextButton(onPressed: _showTips, child: Text('Connection tips')),
      ],
    ),
  );

  Future<void> _showTips() => showAppSheet<void>(
    context,
    title: 'Connection tips',
    child: Text(
      'Keep the TV on. Use the same local network on both devices. A wired TV works too. If you know the TV’s address, use Connect by IP.',
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
        Text('Discovered Displays'),
        Text('${_selectable.length} found'),
      ],
    ),
  );

  String? _platform(RemoteDevice device) =>
      widget.dependencies.providers.manualSetups[device.providerId]?.label ??
      device.manufacturer;

  Widget _newDevice(RemoteDevice device) => Padding(
    key: ValueKey(device.id),
    padding: const EdgeInsets.only(bottom: 6),
    child: DiscoveredDeviceTile(
      device: device,
      subtitle: [
        ?_platform(device),
        ?device.endpoints.firstOrNull?.host,
      ].join(' · '),
      selected: _selectedId == device.id,
      onSelect: model.adding
          ? null
          : () => setState(() => _selectedId = device.id),
      onDetails: () => _deviceDetails(device),
    ),
  );

  Future<void> _deviceDetails(RemoteDevice device) => showAppSheet<void>(
    context,
    title: device.name,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        if (device.manufacturer case final value?)
          Text('Manufacturer · $value'),
        if (device.model case final value?) Text('Model · $value'),
        if (device.endpoints.firstOrNull case final endpoint?) ...[
          Text('IP · ${endpoint.host}'),
          Text('Connection protocol · ${endpoint.scheme}'),
        ],
        if (device.softwareInformation?.operatingSystemVersion
            case final value?)
          Text('OS version · $value'),
        if (device.softwareInformation?.firmwareVersion case final value?)
          Text('Firmware · $value'),
        if (_discoveryProtocols(device) case final protocols?)
          Text('Discovered via · $protocols'),
      ],
    ),
  );

  String? _discoveryProtocols(RemoteDevice device) {
    final protocols = widget.dependencies.discovery.protocolsFor(device);
    if (protocols.isEmpty) {
      return null;
    }
    return protocols
        .map(
          (protocol) => switch (protocol) {
            DiscoveryProtocol.ssdp => 'SSDP',
            DiscoveryProtocol.bonjour => 'Bonjour',
            DiscoveryProtocol.unicast => 'Unicast',
          },
        )
        .join(', ');
  }

  Future<void> _connect() async {
    final device = _selected;
    if (device == null) {
      return;
    }
    await _add(device);
  }

  Widget _registered() => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: Text('Already added (${_registeredResults.length})'),
    children: _registeredResults.map(_knownDevice).toList(),
  );
  Widget _knownDevice(RemoteDevice device) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.check),
    title: Text(model.registered(device)!.name),
    subtitle: Text('Registered · ${device.endpoints.firstOrNull?.host ?? ''}'),
    trailing: TextButton(
      onPressed: model.adding ? null : () => model.updateAddress(device),
      child: Text('Update address'),
    ),
  );
  Future<void> _connectByIp() async {
    final device = await editDevice(context, widget.dependencies);
    if (device != null && mounted) {
      await _pair(device);
    }
  }

  Future<void> _add(RemoteDevice device) async {
    final selected = await model.add(device);
    if (selected != null && mounted) {
      await _pair(selected);
    }
  }

  Future<void> _pair(RemoteDevice device) async {
    final connected = await showDevicePairing(
      context,
      widget.dependencies,
      device,
    );
    if (connected != null && mounted) {
      Navigator.pop(context, connected);
    }
  }
}
