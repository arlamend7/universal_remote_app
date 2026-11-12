import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

import '../../remote/viewmodels/remote_viewmodel.dart';
import 'supported_remote_item_card.dart';

class SupportedRemoteItems extends StatelessWidget {
  const SupportedRemoteItems({super.key, required this.remote});

  final RemoteViewModel remote;

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: remote.controlsChanges, builder: _content);

  Widget _content(BuildContext context, Widget? child) {
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
      (groups[item.category] ??= []).add(item);
    }
    final model = GridRemoteViewModel(remote);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        for (final group in groups.entries) _group(context, group, model),
      ],
    );
  }

  bool _isControl(RemoteItemDefinition<Object> item) => switch (item.layout) {
    GroupLayout() || EmptyLayout() || UnavailableLayout() => false,
    _ => true,
  };

  Widget _group(
    BuildContext context,
    MapEntry<RemoteItemCategory, List<RemoteItemDefinition<Object>>> group,
    GridRemoteViewModel model,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: [
      Semantics(
        header: true,
        child: Text(
          _title(group.key),
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
      LayoutBuilder(
        builder: (_, constraints) => _cards(constraints, group.value, model),
      ),
    ],
  );

  Widget _cards(
    BoxConstraints constraints,
    List<RemoteItemDefinition<Object>> items,
    GridRemoteViewModel model,
  ) {
    const gap = 8.0;
    final columns = (constraints.maxWidth / 128).floor().clamp(1, 3);
    final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final item in items)
          SizedBox(
            width: width,
            child: SupportedRemoteItemCard(definition: item, model: model),
          ),
      ],
    );
  }

  String _title(RemoteItemCategory category) {
    return switch (category) {
      RemoteItemCategory.apps => 'Apps',
      RemoteItemCategory.inputs => 'Inputs',
      RemoteItemCategory.channels => 'Channels',
      RemoteItemCategory.audio => 'Audio',
      RemoteItemCategory.navigation => 'Navigation',
      RemoteItemCategory.keypad => 'Numeric keypad',
      RemoteItemCategory.keys => 'Keys',
      RemoteItemCategory.media => 'Media',
      RemoteItemCategory.information => 'Information',
      RemoteItemCategory.utilities => 'Utilities',
      RemoteItemCategory.climate => 'Climate',
      RemoteItemCategory.volume => 'Volume',
      RemoteItemCategory.mute => 'Mute',
      RemoteItemCategory.channelArrows => 'Channel controls',
      RemoteItemCategory.favouriteChannels => 'Favorite channels',
      RemoteItemCategory.directionPad => 'Direction pad',
      RemoteItemCategory.pinnedApps => 'App shortcuts',
      RemoteItemCategory.pinnedInputs => 'Input shortcuts',
      RemoteItemCategory.activity => 'Activity',
      RemoteItemCategory.accessories => 'Bluetooth accessories',
      RemoteItemCategory.groups => 'Groups',
    };
  }
}
