import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_remote_viewmodel.dart';
import 'grid_button.dart';

class GridVolumeWidget extends StatelessWidget {
  const GridVolumeWidget({super.key, required this.item, required this.model});
  final GridItem item;
  final GridRemoteViewModel model;
  bool get available => model.remote.canChangeVolume;
  int? get level => model.volumeLevel;
  Axis get _position =>
      RemoteItemRegistry.resolve(item.layoutKind).defaultPosition ==
          ItemOrientation.vertical
      ? Axis.vertical
      : Axis.horizontal;

  Widget _plus() => GridButton(
    appearance: item.config,
    label: 'Louder',
    elementStyle: item.elementStyles[TvItems.volumeUp.id],
    icon: model.iconOf(TvItems.volumeUp, item.kind, position: _position),
    showLabel: false,
    repeat: item.config['hold'] == 'true',
    onPressed: available
        ? () => item.element(TvItems.volumeUp).onPressed(model, null)
        : null,
  );
  Widget _minus() => GridButton(
    appearance: item.config,
    label: 'Lower',
    elementStyle: item.elementStyles[TvItems.volumeDown.id],
    icon: model.iconOf(TvItems.volumeDown, item.kind, position: _position),
    showLabel: false,
    repeat: item.config['hold'] == 'true',
    onPressed: available
        ? () => item.element(TvItems.volumeDown).onPressed(model, null)
        : null,
  );
  @override
  Widget build(BuildContext context) => switch (item.layoutKind) {
    GridWidgetKind.volumeUp => _plus(),
    GridWidgetKind.volumeDown => _minus(),
    GridWidgetKind.volumeRocker => Column(
      children: [
        Expanded(child: _plus()),
        Expanded(child: _minus()),
      ],
    ),
    GridWidgetKind.volumeDisplayRocker => Column(
      children: [
        Expanded(child: _plus()),
        _level(),
        Expanded(child: _minus()),
      ],
    ),
    GridWidgetKind.volumeHorizontal => Row(
      children: [
        Expanded(child: _minus()),
        Expanded(child: _plus()),
      ],
    ),
    GridWidgetKind.volumeLevel ||
    GridWidgetKind.volumeSlider ||
    GridWidgetKind.volumeVerticalSlider => _volumeLine(),
    GridWidgetKind.volumeExpanded => Column(
      children: [
        Expanded(child: _slider()),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_level(), _mute(iconOnly: true)],
        ),
      ],
    ),
    GridWidgetKind.volumeDial => _dial(),
    GridWidgetKind.volumePreset => GridButton(
      appearance: item.config,
      label: item.config['label'] ?? 'Volume ${item.config['value'] ?? '15'}',
      icon: Icons.volume_up_outlined,
      onPressed: available
          ? () => item
                .element(TvItems.volumeSlider)
                .commit(
                  model,
                  (int.tryParse(item.config['value'] ?? '')?.clamp(0, 100) ??
                          15)
                      .toDouble(),
                )
          : null,
    ),
    _ => _mute(),
  };
  Widget _volumeLine() {
    final definition = RemoteItemRegistry.resolve(item.kind);
    return Flex(
      direction: _position,
      children: [
        for (final element in definition.elements)
          Expanded(
            flex: element.slots,
            child: element == TvItems.volumeSlider
                ? RotatedBox(
                    quarterTurns: _position == Axis.vertical ? 3 : 0,
                    child: _slider(),
                  )
                : Center(child: _level()),
          ),
      ],
    );
  }

  Widget _level() => Text(
    level == null ? '—' : '$level',
    semanticsLabel: level == null
        ? 'Volume unavailable'
        : 'Volume $level percent',
    textAlign: TextAlign.center,
    style: const TextStyle(fontSize: 22),
  );
  Widget _slider() => Slider(
    value: (level ?? 0).toDouble(),
    max: 100,
    label: level?.toString(),
    semanticFormatterCallback: (value) => '${value.round()} percent',
    onChanged: model.remote.canSetVolume
        ? (value) =>
              item.element(TvItems.volumeSlider).preview?.call(model, value)
        : null,
    onChangeEnd: model.remote.canSetVolume
        ? (value) {
            RemoteFeedback.commit();
            item.element(TvItems.volumeSlider).commit(model, value);
          }
        : null,
  );
  Widget _mute({bool iconOnly = false}) {
    final toggle =
        item.kind != GridWidgetKind.muteOn &&
        item.kind != GridWidgetKind.muteOff;
    final enabled = toggle ? model.remote.canToggleMute : available;
    final value = item.kind == GridWidgetKind.muteOn;
    return GridButton(
      appearance: item.config,
      label:
          item.config['label'] ??
          (toggle
              ? model.remote.volume?.muted == true
                    ? 'Unmute'
                    : 'Mute'
              : value
              ? 'Mute'
              : 'Unmute'),
      icon: model.iconOf(TvItems.mute, item.kind, position: _position),
      showLabel: !iconOnly && item.config['showLabel'] != 'false',
      onPressed: enabled
          ? () => item
                .element(TvItems.mute)
                .onPressed(model, toggle ? null : value)
          : null,
    );
  }

  Widget _dial() => LayoutBuilder(
    builder: (context, constraints) => Semantics(
      label: 'Volume dial',
      value: level?.toString() ?? 'Unavailable',
      onIncrease: available
          ? () => item.element(TvItems.volumeUp).onPressed(model, null)
          : null,
      onDecrease: available
          ? () => item.element(TvItems.volumeDown).onPressed(model, null)
          : null,
      child: GestureDetector(
        onPanUpdate: model.remote.canSetVolume
            ? (details) =>
                  _previewDial(details.localPosition, constraints.biggest)
            : null,
        onPanEnd: model.remote.canSetVolume
            ? (_) {
                RemoteFeedback.commit();
                item
                    .element(TvItems.volumeSlider)
                    .commit(model, (level ?? 0).toDouble());
              }
            : null,
        child: Center(
          child: SizedBox.square(
            dimension:
                math.min(constraints.maxWidth, constraints.maxHeight) - 16,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: (level ?? 0) / 100,
                    strokeWidth: 5,
                    backgroundColor: Theme.of(context).dividerColor,
                  ),
                ),
                _level(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  void _previewDial(Offset point, Size size) {
    final angle =
        (math.atan2(point.dy - size.height / 2, point.dx - size.width / 2) +
            math.pi / 2 +
            math.pi * 2) %
        (math.pi * 2);
    item
        .element(TvItems.volumeSlider)
        .preview
        ?.call(model, angle / (math.pi * 2) * 100);
  }
}
