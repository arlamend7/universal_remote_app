import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import 'grid_climate_widget.dart';
import '../../widgets/grid/grid_surface.dart';
import '../viewmodels/grid_remote_viewmodel.dart';
import 'grid_volume_widget.dart';
import 'grid_navigation_widget.dart';
import 'grid_targets_widget.dart';
import 'grid_channels_widget.dart';
import 'grid_keypad_widget.dart';
import 'grid_information_widget.dart';
import 'grid_media_widget.dart';
import 'grid_utility_widget.dart';
import 'grid_pointer_widget.dart';
import 'grid_unavailable.dart';
import 'grid_special_key_widget.dart';
import 'grid_remote_item.dart';

class GridRemoteWidget extends StatelessWidget {
  const GridRemoteWidget({super.key, required this.item, required this.model});
  final GridItem item;
  final GridRemoteViewModel model;
  @override
  Widget build(BuildContext context) {
    final definition = RemoteItemRegistry.resolve(item.kind);
    return switch ((item.kind, definition.category)) {
      (
        GridWidgetKind.unknown ||
            GridWidgetKind.previous ||
            GridWidgetKind.next ||
            GridWidgetKind.seek ||
            GridWidgetKind.artwork,
        _,
      ) =>
        GridUnavailable(
          title: definition.name,
          reason: 'This control is unavailable for this device.',
        ),
      (GridWidgetKind.group, _) => _group(),
      (GridWidgetKind.touchpad, _) => GridPointerWidget(
        model: model,
        configuration: TouchpadConfiguration.fromSettings(item.config),
      ),
      (GridWidgetKind.keypad, _) => GridKeypadWidget(model: model),
      (GridWidgetKind.channelShortcut || GridWidgetKind.channelGroup, _) =>
        GridTargetsWidget(item: item, model: model),
      (_, RemoteItemCategory.navigation) => GridNavigationWidget(
        item: item,
        model: model,
      ),
      (_, RemoteItemCategory.audio) => GridVolumeWidget(
        item: item,
        model: model,
      ),
      (GridWidgetKind.currentInput, _) => GridInformationWidget(
        item: item,
        model: model,
      ),
      (_, RemoteItemCategory.apps || RemoteItemCategory.inputs) =>
        GridTargetsWidget(item: item, model: model),
      (_, RemoteItemCategory.channels) => GridChannelsWidget(
        item: item,
        model: model,
      ),
      (_, RemoteItemCategory.information) => GridInformationWidget(
        item: item,
        model: model,
      ),
      (_, RemoteItemCategory.keys) => GridSpecialKeyWidget(
        item: item,
        model: model,
      ),
      (_, RemoteItemCategory.media) => GridMediaWidget(
        item: item,
        model: model,
      ),
      (_, RemoteItemCategory.utilities) => GridUtilityWidget(
        item: item,
        model: model,
      ),
      (_, RemoteItemCategory.climate) => GridClimateWidget(model: model),
      (_, RemoteItemCategory.groups) => const SizedBox.shrink(),
    };
  }

  Widget _group() => LayoutBuilder(
    builder: (_, constraints) {
      final cell = (constraints.maxHeight - (item.h - 1) * 8) / item.h;
      return Stack(
        children: [
          GridSurface(
            layout: GridLayout(item.children),
            columns: item.w,
            rows: item.h,
            cellHeight: cell,
            itemBuilder: (child) => GridRemoteItem(item: child, model: model),
          ),
          if (item.config['showTitle'] == 'true')
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: cell,
              child: Center(
                child: Text(
                  item.config['label'] ?? 'Group',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      );
    },
  );
}
