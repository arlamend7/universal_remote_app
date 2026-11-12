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
import '../../../shared/localization/journey_text.dart';
import '../viewmodels/discovery_viewmodel.dart';
import 'device_discovery_sheet.dart';

class DeviceDiscoveryState extends State<DeviceDiscoverySheet> {
  String? _selectedId;

  String _text(String en, String pt) => journeyText(context, en, pt);

  RemoteDevice? get _selected =>
      model.fresh.where((device) => device.id == _selectedId).firstOrNull;
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
    title: _text('Find Nearby Devices', 'Encontrar dispositivos próximos'),
    child: _body(),
    footer: _footer(),
  );

  Widget _body() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (model.searching) const DiscoveryProgress(),
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
        _message(
          Icons.pause_circle_outline,
          _text('Search cancelled.', 'Busca cancelada.'),
        ),
      if (_showEmpty) _empty(),
      if (model.unresolvedCount > 0)
        _message(
          Icons.help_outline,
          _text(
            '${model.unresolvedCount} unrecognized discovery responses',
            '${model.unresolvedCount} respostas de descoberta não reconhecidas',
          ),
        ),
      if (model.fresh.isNotEmpty) _resultsHeading(),
      ...model.fresh.map(_newDevice),
      if (model.known.isNotEmpty) _registered(),
      if (model.fresh.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            _text(
              'Keep your TV on and on the same local network.',
              'Mantenha a TV ligada e na mesma rede local.',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      if (model.statuses.isNotEmpty)
        ExpansionTile(
          key: ValueKey(widget.dependencies.discovery.searchId),
          tilePadding: EdgeInsets.zero,
          title: Text(_text('Search details', 'Detalhes da busca')),
          children: [DiscoveryDetails(model: model)],
        ),
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
      if (model.fresh.isNotEmpty)
        FilledButton(
          onPressed: _selected == null || model.adding ? null : _connect,
          child: Text(_text('Connect', 'Conectar')),
        ),
      _actions(),
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
      label: Text(_text('Connect by IP', 'Conectar por IP')),
    ),
    primary: FilledButton.icon(
      onPressed: model.adding
          ? null
          : model.searching
          ? model.cancel
          : _search,
      icon: Icon(model.searching ? Icons.close : Icons.refresh, size: 18),
      label: Text(
        model.searching
            ? _text('Cancel search', 'Cancelar busca')
            : _text('Search again', 'Buscar novamente'),
      ),
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
          _text('No Displays Found', 'Nenhum dispositivo encontrado'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          _text(
            'Check that your TV is on and reachable on the local network.',
            'Confira se a TV está ligada e acessível na rede local.',
          ),
          textAlign: TextAlign.center,
        ),
        TextButton(
          onPressed: _showTips,
          child: Text(_text('Connection tips', 'Ver dicas de conexão')),
        ),
      ],
    ),
  );

  Future<void> _showTips() => showAppSheet<void>(
    context,
    title: _text('Connection tips', 'Dicas de conexão'),
    child: Text(
      _text(
        'Keep the TV on. Use the same local network on both devices. A wired TV works too. If you know the TV’s address, use Connect by IP.',
        'Mantenha a TV ligada. Use a mesma rede local nos dois dispositivos. Uma TV conectada por cabo também funciona. Se souber o endereço da TV, use Conectar por IP.',
      ),
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
        Text(_text('Discovered Displays', 'Dispositivos encontrados')),
        Text(
          _text(
            '${model.fresh.length} found',
            '${model.fresh.length} encontrados',
          ),
        ),
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
          Text('${_text('Manufacturer', 'Fabricante')} · $value'),
        if (device.model case final value?)
          Text('${_text('Model', 'Modelo')} · $value'),
        if (device.endpoints.firstOrNull case final endpoint?) ...[
          Text('IP · ${endpoint.host}'),
          Text(
            '${_text('Connection protocol', 'Protocolo de conexão')} · ${endpoint.scheme}',
          ),
        ],
        if (device.metadata['osversion'] case final value?)
          Text('${_text('OS version', 'Versão do sistema')} · $value'),
        if (device.metadata['firmwareversion'] case final value?)
          Text('${_text('Firmware', 'Firmware')} · $value'),
      ],
    ),
  );

  Future<void> _connect() async {
    final device = _selected;
    if (device == null) {
      return;
    }
    await _add(device);
  }

  Widget _registered() => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: Text(
      _text(
        'Already added (${model.known.length})',
        'Já adicionados (${model.known.length})',
      ),
    ),
    children: model.known.map(_knownDevice).toList(),
  );
  Widget _knownDevice(RemoteDevice device) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.check),
    title: Text(model.registered(device)!.name),
    subtitle: Text('Registered · ${device.endpoints.firstOrNull?.host ?? ''}'),
    trailing: TextButton(
      onPressed: model.adding ? null : () => model.updateAddress(device),
      child: Text(_text('Update address', 'Atualizar endereço')),
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
