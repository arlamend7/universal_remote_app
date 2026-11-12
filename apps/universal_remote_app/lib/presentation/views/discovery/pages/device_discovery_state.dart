import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/remote_ui.dart';

import '../../../shared/widgets/setup/push_setup_page.dart';
import '../../../shared/widgets/setup/setup_step_page.dart';
import '../../devices/widgets/discovery_progress.dart';
import '../../pairing/pages/show_device_pairing.dart';
import '../../../../domains/discovery/models/connection_issue_type.dart';
import '../widgets/discovery_details.dart';
import '../widgets/discovery_issue.dart';
import '../widgets/discovered_device_tile.dart';
import '../viewmodels/discovery_viewmodel.dart';
import 'device_discovery_page.dart';
import 'manual_address_page.dart';

class DeviceDiscoveryState extends State<DeviceDiscoveryPage> {
  String? _lastConnectionId;

  List<RemoteDevice> get _connectable => model.found
      .where(
        (device) =>
            device.id == _lastConnectionId || model.registered(device) == null,
      )
      .toList();
  List<RemoteDevice> get _registeredResults =>
      model.known.where((device) => device.id != _lastConnectionId).toList();
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
      ListenableBuilder(listenable: model, builder: _page);

  Widget _page(BuildContext context, Widget? child) => SetupStepPage(
    step: 2,
    title: 'Find Devices',
    bodyPadding: const EdgeInsets.symmetric(vertical: 16),
    body: _body(),
    floating: model.searching ? const DiscoveryProgress() : null,
    primary: _searchAction(),
    secondary: OutlinedButton.icon(
      onPressed: model.adding ? null : _connectByIp,
      icon: const Icon(Icons.link),
      label: const Text('Connect by IP'),
    ),
    footerLink: TextButton(
      onPressed: _showDetails,
      child: const Text('Search details'),
    ),
  );

  Future<void> _showDetails() => showAppSheet<void>(
    context,
    title: 'Search details',
    child: ListenableBuilder(
      listenable: model,
      builder: (_, _) => model.statuses.isEmpty
          ? const Text('Search details will appear as discovery runs.')
          : DiscoveryDetails(model: model),
    ),
  );

  Widget _body() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      if (_connectionIssue() case final issue?) _inset(issue),
      if (widget.dependencies.discovery.catalogOffline.value &&
          !_offlineDismissed)
        _inset(
          DiscoveryIssue(
            type: ConnectionIssueType.internetUnavailable,
            retry: widget.dependencies.discovery.refreshCatalog,
            dismiss: () => setState(() => _offlineDismissed = true),
          ),
        ),
      if (!model.searching && model.cancelled)
        _inset(_message(Icons.pause_circle_outline, 'Search cancelled.')),
      if (_showEmpty) _inset(_empty()),
      if (model.unresolvedCount > 0)
        _inset(
          _message(
            Icons.help_outline,
            '${model.unresolvedCount} unrecognized discovery responses',
          ),
        ),
      if (_connectable.isNotEmpty) _inset(_resultsHeading()),
      if (_connectable.isNotEmpty)
        Column(children: _connectable.map(_newDevice).toList()),
      if (_registeredResults.isNotEmpty) _inset(_registered()),
    ],
  );

  Widget _inset(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: child,
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

  Future<void> _search() {
    setState(() {
      _offlineDismissed = false;
      _lastConnectionId = null;
    });
    return model.search();
  }

  Widget _searchAction() => FilledButton.icon(
    onPressed: model.adding
        ? null
        : model.searching
        ? model.cancel
        : _search,
    icon: Icon(model.searching ? Icons.close : Icons.refresh),
    label: Text(model.searching ? 'Cancel search' : 'Search again'),
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

  Widget _resultsHeading() => Text(
    'DEVICES FOUND (${_connectable.length})',
    style: Theme.of(context).textTheme.labelLarge,
  );

  String? _platform(RemoteDevice device) =>
      widget.dependencies.providers.manualSetups[device.providerId]?.label ??
      device.manufacturer;

  Widget _newDevice(RemoteDevice device) => DiscoveredDeviceTile(
    key: ValueKey(device.id),
    device: device,
    subtitle: [
      ?device.endpoints.firstOrNull?.host,
      ?_platform(device),
      ?device.softwareInformation?.operatingSystemVersion,
    ].join(' · '),
    onConnect: model.adding ? null : () => _add(device),
    onDetails: () => _deviceDetails(device),
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
    if (ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final connected = await pushSetupPage<RemoteDevice>(
      context,
      ManualAddressPage(
        dependencies: widget.dependencies,
        onSearch: _searchWhenIdle,
      ),
    );
    if (connected != null && mounted) {
      Navigator.pop(context, connected);
    }
  }

  void _searchWhenIdle() {
    if (!mounted || model.searching || model.adding) {
      return;
    }
    unawaited(_search());
  }

  Future<void> _add(RemoteDevice device) async {
    if (model.adding || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _lastConnectionId = device.id;
    final selected = model.connectionTarget(device);
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
