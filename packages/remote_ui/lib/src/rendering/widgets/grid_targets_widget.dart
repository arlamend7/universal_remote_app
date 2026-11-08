import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_remote_viewmodel.dart';
import '../../widgets/apps/tv_app_icon.dart';
import 'grid_button.dart';
import 'grid_unavailable.dart';

class GridTargetsWidget extends StatelessWidget {
  const GridTargetsWidget({super.key, required this.item, required this.model});
  final GridItem item;
  final GridRemoteViewModel model;
  static const _gap = 4.0;
  bool get inputs => item.kind.name.startsWith('input');
  bool get channels =>
      item.kind == GridWidgetKind.channelShortcut ||
      item.kind == GridWidgetKind.channelGroup;
  @override
  Widget build(BuildContext context) {
    if (item.kind == GridWidgetKind.apps) {
      return GridButton(
        appearance: item.config,
        label: item.config['label'] ?? 'Apps',
        icon: Icons.apps,
        onPressed: model.remote.canLaunchApps
            ? () => model.choose(
                context,
                'Apps',
                item.element(TvItems.applications),
              )
            : null,
      );
    }
    if (item.kind == GridWidgetKind.inputs) {
      return GridButton(
        appearance: item.config,
        label: item.config['label'] ?? 'Inputs',
        icon: Icons.input,
        onPressed: model.remote.canSelectInput
            ? () =>
                  model.choose(context, 'Inputs', item.element(TvItems.inputs))
            : null,
      );
    }
    final targets =
        item.kind == GridWidgetKind.recentApps && model.previewData == null
        ? model.recentApps
        : model.targets(item);
    if (targets.isEmpty) {
      return const GridUnavailable(
        title: 'Choose shortcuts',
        reason: 'Select this widget in the grid editor and configure its apps, inputs or channels. Recently launched apps appear after successful launches from this grid.',
      );
    }
    if (item.kind == GridWidgetKind.appShortcut ||
        item.kind == GridWidgetKind.appIcon ||
        item.kind == GridWidgetKind.inputShortcut ||
        item.kind == GridWidgetKind.channelShortcut) {
      return _button(targets.first);
    }
    if (item.kind == GridWidgetKind.appGrid ||
        item.kind == GridWidgetKind.inputGrid ||
        item.kind == GridWidgetKind.channelGroup) {
      return GridView.count(
        padding: EdgeInsets.zero,
        crossAxisCount: item.w.clamp(1, 4),
        crossAxisSpacing: _gap,
        mainAxisSpacing: _gap,
        children: targets.map(_button).toList(),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      scrollDirection: Axis.horizontal,
      itemCount: targets.length,
      separatorBuilder: (_, _) => const SizedBox(width: _gap),
      itemBuilder: (_, index) =>
          SizedBox(width: 76, child: _button(targets[index])),
    );
  }

  Widget _button((String, String) target) => GridButton(
    appearance: item.config,
    label:
        {
          'appShortcut',
          'appIcon',
          'inputShortcut',
          'channelShortcut',
        }.contains(item.kind.name)
        ? item.config['label'] ?? target.$2
        : target.$2,
    icon: channels
        ? Icons.live_tv
        : inputs
        ? Icons.input
        : Icons.apps,
    iconWidget: inputs || channels
        ? null
        : TvAppIcon(appId: target.$1, name: target.$2),
    showLabel:
        item.kind != GridWidgetKind.appIcon &&
        item.config['showLabel'] != 'false',
    onPressed: _enabled && !_missing(target.$1)
        ? () => _activate(target)
        : null,
    unavailableReason: _missing(target.$1) ? 'Unavailable on this TV' : null,
  );
  bool _missing(String id) => !inputs && !channels && model.isAppMissing(id);
  bool get _enabled =>
      model.ready &&
      (channels
          ? model.supports(RemoteCapability.channelSelection)
          : inputs
          ? model.remote.canSelectInput
          : model.remote.canLaunchApps);
  void _activate((String, String) target) {
    if (channels) {
      item
          .element(TvItems.channels)
          .onSelected(model, DeviceChannel(target.$1, target.$2, ''));
      return;
    }
    if (inputs) {
      item
          .element(TvItems.inputs)
          .onSelected(model, DeviceInput(target.$1, target.$2));
      return;
    }
    item
        .element(TvItems.applications)
        .onSelected(model, DeviceApplication(target.$1, target.$2));
  }
}
