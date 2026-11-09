import 'package:flutter/material.dart';

import '../viewmodels/device_details_viewmodel.dart';
import 'capability_evidence_list.dart';

class DeviceDetailsContent extends StatelessWidget {
  const DeviceDetailsContent({super.key, required this.model});
  final DeviceDetailsViewModel model;
  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: model.changes, builder: _body);
  Widget _body(BuildContext context, Widget? child) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(model.device.name, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 16),
      _value('Status', model.connected ? 'Connected' : 'Offline'),
      _value('Network wake', model.wakeStatus),
      _value(
        'Address',
        model.device.endpoints.firstOrNull?.host ?? 'Not configured',
      ),
      _value(
        'TV',
        [
          model.device.manufacturer,
          model.device.model,
        ].whereType<String>().join(' · '),
      ),
      if (model.currentApp != null) _value('Current app', model.currentApp!),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () => model.customize(context),
        child: const Text('Customize remote'),
      ),
      _action('Rename', Icons.edit_outlined, () => model.rename(context)),
      _action('Connection settings', Icons.link, () => model.edit(context)),
      _advanced(context),
    ],
  );
  Widget _value(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );
  Widget _action(String title, IconData icon, VoidCallback action) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: action,
  );
  Widget _advanced(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: const Text('Advanced'),
    children: [
      if (model.canChooseProvider)
        _action(
          'Preferred integration',
          Icons.tune,
          () => model.chooseProvider(context),
        ),
      if (model.canLink)
        _action(
          'Link saved integration',
          Icons.add_link,
          () => model.linkProfile(context),
        ),
      if (model.canUnlink)
        _action(
          'Unlink integration',
          Icons.link_off,
          () => model.unlinkProfile(context),
        ),
      _action('Re-pair', Icons.refresh, () => model.rePair(context)),
      if (model.selected)
        _action('Disconnect', Icons.link_off, () => model.disconnect(context)),
      CapabilityEvidenceList(evidence: model.evidence),
      TextButton(
        onPressed: () => _forget(context),
        child: Text(
          'Forget device',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    ],
  );
  Future<void> _forget(BuildContext context) async {
    final removed = await model.forget(context);
    if (removed && context.mounted) {
      Navigator.pop(context);
    }
  }
}
