import 'package:flutter/material.dart';
import 'package:remote_ui/remote_ui.dart';

import '../../../shared/widgets/setup/setup_step_page.dart';
import '../../devices/forms/connection_settings_fields.dart';
import '../../devices/viewmodels/device_editor_viewmodel.dart';
import '../../pairing/pages/show_device_pairing.dart';
import '../forms/manual_address_fields.dart';
import 'manual_address_page.dart';

class ManualAddressState extends State<ManualAddressPage> {
  late final model = DeviceEditorViewModel.forApp(widget.dependencies);

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: model.changes, builder: _page);

  Widget _page(BuildContext context, Widget? child) => SetupStepPage(
    step: 2,
    title: 'Connect by IP',
    headerAction: IconButton.filledTonal(
      tooltip: 'Connection settings',
      onPressed: _showSettings,
      icon: const Icon(Icons.tune),
    ),
    body: ManualAddressFields(model: model, onSubmitted: _connect),
    primary: FilledButton.icon(
      onPressed: model.checking.value ? null : _connect,
      icon: const Icon(Icons.arrow_forward),
      iconAlignment: IconAlignment.end,
      label: Text(model.checking.value ? 'Checking TV…' : 'Connect'),
    ),
    secondary: OutlinedButton.icon(
      onPressed: _search,
      icon: const Icon(Icons.search),
      label: const Text('Search'),
    ),
    footerLink: TextButton(
      onPressed: _showAddressHelp,
      child: const Text('Need help with the IP?'),
    ),
  );

  Future<void> _showSettings() => showAppSheet<void>(
    context,
    title: 'Connection settings',
    child: ListenableBuilder(
      listenable: model.changes,
      builder: (_, _) => ConnectionSettingsFields(model: model),
    ),
  );

  Future<void> _showAddressHelp() => showAppSheet<void>(
    context,
    title: 'Finding the TV’s IP address',
    child: const Text(
      'On the TV, open Settings › Network, select the connected Wi-Fi or Ethernet network and look for the IP address. Your router’s app also lists connected devices. The TV and this device must be on the same local network.',
    ),
  );

  void _search() {
    Navigator.pop(context);
    widget.onSearch();
  }

  Future<void> _connect() async {
    if (ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final device = await model.submit();
    if (device == null || !mounted) {
      return;
    }
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
