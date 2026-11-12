import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

import '../../../shared/localization/journey_text.dart';
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
      return Text(
        journeyText(
          context,
          'The TV disconnected. Open the remote to reconnect.',
          'A TV desconectou. Abra o controle para reconectar.',
        ),
      );
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
          _title(context, group.key),
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

  String _title(BuildContext context, RemoteItemCategory category) {
    String tr(String en, String pt) => journeyText(context, en, pt);
    return switch (category) {
      RemoteItemCategory.apps => tr('Apps', 'Aplicativos'),
      RemoteItemCategory.inputs => tr('Inputs', 'Entradas'),
      RemoteItemCategory.channels => tr('Channels', 'Canais'),
      RemoteItemCategory.audio => tr('Audio', 'Áudio'),
      RemoteItemCategory.navigation => tr('Navigation', 'Navegação'),
      RemoteItemCategory.keypad => tr('Numeric keypad', 'Teclado numérico'),
      RemoteItemCategory.keys => tr('Keys', 'Teclas'),
      RemoteItemCategory.media => tr('Media', 'Mídia'),
      RemoteItemCategory.information => tr('Information', 'Informações'),
      RemoteItemCategory.utilities => tr('Utilities', 'Utilitários'),
      RemoteItemCategory.climate => tr('Climate', 'Climatização'),
      RemoteItemCategory.volume => tr('Volume', 'Volume'),
      RemoteItemCategory.mute => tr('Mute', 'Silenciar'),
      RemoteItemCategory.channelArrows => tr(
        'Channel controls',
        'Controles de canal',
      ),
      RemoteItemCategory.favouriteChannels => tr(
        'Favorite channels',
        'Canais favoritos',
      ),
      RemoteItemCategory.directionPad => tr(
        'Direction pad',
        'Controle direcional',
      ),
      RemoteItemCategory.pinnedApps => tr(
        'App shortcuts',
        'Atalhos de aplicativos',
      ),
      RemoteItemCategory.pinnedInputs => tr(
        'Input shortcuts',
        'Atalhos de entradas',
      ),
      RemoteItemCategory.activity => tr('Activity', 'Atividade'),
      RemoteItemCategory.accessories => tr(
        'Bluetooth accessories',
        'Acessórios Bluetooth',
      ),
      RemoteItemCategory.groups => tr('Groups', 'Grupos'),
    };
  }
}
