import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

import '../../../../data/network/services/preparation_network.dart';
import '../../../shared/widgets/setup/push_setup_page.dart';
import '../../../shared/widgets/setup/setup_display.dart';
import '../../../shared/widgets/setup/setup_step_page.dart';
import '../../devices/modals/edit_device.dart';
import '../../pairing/pages/show_device_pairing.dart';
import '../widgets/tv_preparation_card.dart';
import 'device_discovery_page.dart';
import 'device_preparation_page.dart';

class DevicePreparationState extends State<DevicePreparationPage> {
  bool _confirmed = false;
  bool _requestingName = false;
  int _networkRead = 0;
  PreparationNetwork? _network;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refreshNetwork);
    unawaited(_refreshNetwork());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refreshNetwork() async {
    final read = ++_networkRead;
    final network = await readPreparationNetwork();
    if (!mounted || read != _networkRead) {
      return;
    }
    setState(() => _network = network);
  }

  Future<void> _showWifiName() async {
    setState(() => _requestingName = true);
    await requestWifiNamePermission();
    if (!mounted) {
      return;
    }
    await _refreshNetwork();
    if (mounted) {
      setState(() => _requestingName = false);
    }
  }

  bool get _networkConnected =>
      _network?.transport == 'wifi' || _network?.transport == 'ethernet';

  String get _networkStatus => switch (_network?.transport) {
    'wifi' => 'Wi-Fi connected',
    'ethernet' => 'Ethernet connected',
    'offline' => 'No Wi-Fi or Ethernet connection',
    _ => _network == null ? 'Checking network…' : 'Network status unavailable',
  };

  Widget _networkBadge(ColorScheme colors) {
    final network = _network;
    final icon = Icon(
      network?.transport == 'ethernet' ? Icons.lan_outlined : Icons.wifi,
      color: colors.primary,
      size: 16,
    );
    if (network?.canRequestName == true && network?.name == null) {
      return ActionChip(
        avatar: icon,
        label: const Text('Show Wi-Fi name'),
        onPressed: _requestingName ? null : _showWifiName,
      );
    }
    final label =
        network?.name ??
        switch (network?.transport) {
          'wifi' => 'Wi-Fi name unavailable',
          'ethernet' => 'Ethernet',
          'offline' => 'No local network',
          _ => 'Network',
        };
    final badge = Chip(
      avatar: icon,
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    final name = network?.name;
    return name == null
        ? badge
        : Tooltip(message: name, excludeFromSemantics: true, child: badge);
  }

  @override
  Widget build(BuildContext context) => SetupStepPage(
    step: 1,
    title: 'Preparation',
    body: _requirements(context),
    primary: FilledButton.icon(
      onPressed: _confirmed ? _search : null,
      icon: const Icon(Icons.radar),
      label: const Text('Search for devices'),
    ),
    secondary: OutlinedButton.icon(
      onPressed: _connectByIp,
      icon: const Icon(Icons.link),
      label: const Text('Connect by IP'),
    ),
    footerLink: TextButton(
      onPressed: _connectionDetails,
      child: const Text('Connection details'),
    ),
  );

  Widget _requirements(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        SetupDisplay(
          minHeight: 172,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.primary,
                child: const Icon(Icons.power_settings_new),
              ),
              _networkBadge(theme.colorScheme),
            ],
          ),
        ),
        Text('CONNECTION REQUIREMENTS', style: theme.textTheme.labelLarge),
        TvPreparationCard(
          icon: Icons.tv_outlined,
          title: 'My TV is on',
          description: 'Wake the TV from standby before searching.',
          confirmed: _confirmed,
          onChanged: (value) => setState(() => _confirmed = value ?? false),
        ),
        TvPreparationCard(
          icon: _network?.transport == 'ethernet'
              ? Icons.lan_outlined
              : Icons.wifi,
          title: 'Same local network',
          description: _networkStatus,
          confirmed: _networkConnected,
        ),
      ],
    );
  }

  Future<void> _connectionDetails() => showAppSheet<void>(
    context,
    title: 'Connection details',
    child: const Text(
      'This check shows your device’s connection. Searching checks whether your TV is reachable. You can also connect by IP.',
    ),
  );

  Future<void> _search() async {
    final device = await pushSetupPage<RemoteDevice>(
      context,
      DeviceDiscoveryPage(dependencies: widget.dependencies),
    );
    _finish(device);
  }

  Future<void> _connectByIp() async {
    final device = await editDevice(context, widget.dependencies);
    if (device == null || !mounted) {
      return;
    }
    _finish(await showDevicePairing(context, widget.dependencies, device));
  }

  void _finish(RemoteDevice? device) {
    if (device != null && mounted) {
      Navigator.pop(context, device);
    }
  }
}
