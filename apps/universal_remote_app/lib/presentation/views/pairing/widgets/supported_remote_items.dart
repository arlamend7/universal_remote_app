import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

import '../../remote/viewmodels/remote_viewmodel.dart';
import 'supported_remote_item_card.dart';

class SupportedRemoteItems extends StatelessWidget {
  const SupportedRemoteItems({super.key, required this.remote});

  final RemoteViewModel remote;

  @override
  Widget build(BuildContext context) {
    final controller = remote.connection.controller;
    if (controller == null || remote.state != DeviceConnectionState.connected) {
      return Text('The TV disconnected. Open the remote to reconnect.');
    }
    final items = RemoteItemRegistry.search(
      capabilities: resolvedCapabilities(controller),
      where: _isControl,
    );
    final groups = <RemoteItemCategory, List<RemoteItemDefinition<Object>>>{};
    for (final item in items) {
      (groups[_section(item.category)] ??= []).add(item);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        Text(
          'Detected controls',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        LayoutBuilder(
          builder: (_, constraints) => _cards(context, constraints, groups),
        ),
      ],
    );
  }

  bool _isControl(RemoteItemDefinition<Object> item) => switch (item.layout) {
    GroupLayout() || EmptyLayout() || UnavailableLayout() => false,
    _ => true,
  };

  Widget _cards(
    BuildContext context,
    BoxConstraints constraints,
    Map<RemoteItemCategory, List<RemoteItemDefinition<Object>>> groups,
  ) {
    const gap = 10.0;
    final columns = constraints.maxWidth >= 270 ? 2 : 1;
    final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final group in groups.entries) _card(context, group, width),
      ],
    );
  }

  Widget _card(
    BuildContext context,
    MapEntry<RemoteItemCategory, List<RemoteItemDefinition<Object>>> group,
    double width,
  ) {
    final (title, icon) = _heading(group.key);
    return SizedBox(
      width: width,
      child: SupportedRemoteItemCard(
        title: title,
        icon: icon,
        onTap: () => _showGroup(context, group.key, group.value),
      ),
    );
  }

  Future<void> _showGroup(
    BuildContext context,
    RemoteItemCategory category,
    List<RemoteItemDefinition<Object>> items,
  ) => showAppSheet<void>(
    context,
    title: _heading(category).$1,
    child: Column(
      children: [
        for (final item in items)
          ListTile(
            title: Text(item.name),
            subtitle: item.description == null ? null : Text(item.description!),
          ),
      ],
    ),
  );

  RemoteItemCategory _section(RemoteItemCategory category) =>
      switch (category) {
        RemoteItemCategory.directionPad ||
        RemoteItemCategory.keypad ||
        RemoteItemCategory.keys => RemoteItemCategory.navigation,
        RemoteItemCategory.volume ||
        RemoteItemCategory.mute => RemoteItemCategory.audio,
        RemoteItemCategory.channelArrows ||
        RemoteItemCategory.favouriteChannels => RemoteItemCategory.channels,
        RemoteItemCategory.pinnedApps => RemoteItemCategory.apps,
        RemoteItemCategory.pinnedInputs => RemoteItemCategory.inputs,
        RemoteItemCategory.activity => RemoteItemCategory.information,
        _ => category,
      };

  (String, IconData) _heading(RemoteItemCategory section) => switch (section) {
    RemoteItemCategory.apps => ('Apps', Icons.apps),
    RemoteItemCategory.inputs => ('Inputs', Icons.input),
    RemoteItemCategory.channels => ('Channels', Icons.live_tv_outlined),
    RemoteItemCategory.audio => ('Volume & audio', Icons.volume_up_outlined),
    RemoteItemCategory.navigation => ('Navigation', Icons.open_with),
    RemoteItemCategory.media => ('Media', Icons.play_circle_outline),
    RemoteItemCategory.information => ('Information', Icons.info_outline),
    RemoteItemCategory.utilities => ('Device tools', Icons.power_settings_new),
    RemoteItemCategory.climate => ('Climate', Icons.thermostat),
    RemoteItemCategory.accessories => (
      'Bluetooth accessories',
      Icons.bluetooth,
    ),
    _ => (section.label, Icons.tune),
  };
}
