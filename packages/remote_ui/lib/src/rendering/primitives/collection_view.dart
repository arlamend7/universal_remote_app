import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_remote_viewmodel.dart';
import '../../layout/models/square_grid_metrics.dart';
import 'action_button.dart';
import 'unavailable_notice.dart';
import 'styled_element.dart';

/// Draws any [RemoteCollection] item: a picker button, pinned shortcuts or a
/// row/grid of entries. The definition chooses the collection and layout; this
/// widget never asks which definitionId of entry (app, input, channel) it shows.
class CollectionView extends StatelessWidget {
  const CollectionView({
    super.key,
    required this.definition,
    required this.item,
    required this.model,
  });
  final RemoteItemDefinition<Object> definition;
  final GridItem item;
  final GridRemoteViewModel model;
  static const _gap = SquareGridMetrics.gap;

  RemoteCollection<GridRemoteViewModel, Object> get _collection => definition
      .elements
      .whereType<RemoteCollection<GridRemoteViewModel, Object>>()
      .first;
  CollectionPresentation get _layout =>
      (definition.layout as CollectionLayout).presentation;

  @override
  Widget build(BuildContext context) => StyledElement(
    style: item.elementStyles[_collection.id],
    child: _content(context),
  );

  Widget _content(BuildContext context) {
    if (_layout == CollectionPresentation.chooser) {
      return _chooser(context);
    }
    final targets = _targets;
    if (targets.isEmpty) {
      return const UnavailableNotice(
        title: 'Choose shortcuts',
        reason: 'Select this widget in the grid editor and configure its shortcuts. Recently launched apps appear after successful launches from this grid.',
      );
    }
    return switch (_layout) {
      CollectionPresentation.shortcut ||
      CollectionPresentation.icon => _button(targets.first),
      CollectionPresentation.grid => _grid(targets),
      _ => _strip(targets),
    };
  }

  List<(String, String)> get _targets =>
      _layout == CollectionPresentation.recents && model.previewData == null
      ? model.recentApps
      : model.targets(item, _collection);

  Widget _chooser(BuildContext context) => ActionButton(
    appearance: item.config,
    label: item.config['label'] ?? _collection.title,
    icon: _collection.icon!(model.elementContext(item)),
    onPressed: definition.isAvailableOn(model.remote)
        ? () => model.choose(context, _collection.title, _collection)
        : null,
  );

  Widget _grid(List<(String, String)> targets) => GridView.count(
    padding: const EdgeInsets.all(_gap / 2),
    crossAxisCount: item.w.clamp(1, 4),
    crossAxisSpacing: _gap,
    mainAxisSpacing: _gap,
    children: targets.map(_button).toList(),
  );

  Widget _strip(List<(String, String)> targets) => ListView.separated(
    padding: const EdgeInsets.all(_gap / 2),
    scrollDirection: Axis.horizontal,
    itemCount: targets.length,
    separatorBuilder: (_, _) => const SizedBox(width: _gap),
    itemBuilder: (_, index) =>
        SizedBox(width: 76, child: _button(targets[index])),
  );

  Widget _button((String, String) target) {
    final (id, name) = target;
    final missing = _collection.trackedByDevice && model.isAppMissing(id);
    final style =
        item.elementStyles[_layout.isSingle
            ? _collection.id
            : _collection.entryStyleKey(id)];
    return StyledElement(
      style: _layout.isSingle ? null : style,
      child: _shortcut(id, name, missing, style),
    );
  }

  Widget _shortcut(
    String id,
    String name,
    bool missing,
    RemoteElementStyle? style,
  ) {
    final showLabel = style?.showLabel;
    return ActionButton(
      appearance: {
        ...item.config,
        if (showLabel != null) 'showLabel': '$showLabel',
      },
      elementStyle: style,
      label: _layout.isSingle ? item.config['label'] ?? name : name,
      icon: _collection.icon!(model.elementContext(item)),
      iconWidget: _collection.leading?.call(id, name),
      showLabel: showLabel ?? (_layout != CollectionPresentation.icon),
      onPressed: definition.isAvailableOn(model.remote) && !missing
          ? () => _collection.select(model, id, name)
          : null,
      unavailableReason: missing ? 'Unavailable on this TV' : null,
    );
  }
}
