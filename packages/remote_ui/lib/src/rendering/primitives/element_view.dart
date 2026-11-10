import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_remote_viewmodel.dart';
import 'action_button.dart';
import 'info_display.dart';
import 'slider_input.dart';
import 'text_entry_button.dart';
import 'styled_element.dart';

/// Draws one registered element by its type: a press-only action becomes a
/// button, information becomes text, a numeric input becomes a slider.
class ElementView extends StatelessWidget {
  const ElementView({
    super.key,
    required this.definition,
    required this.element,
    required this.item,
    required this.model,
    required this.axis,
  });
  final RemoteItemDefinition<Object> definition;
  final RemoteElement<Object> element;
  final GridItem item;
  final GridRemoteViewModel model;
  final Axis axis;

  @override
  Widget build(BuildContext context) => StyledElement(
    style: element is RemoteInfo<Object>
        ? null
        : item.elementStyles[element.id],
    child: _content(context),
  );

  Widget _content(BuildContext context) {
    final element = this.element;
    if (element is RemoteAction<Object>) {
      return _button(context, element);
    }
    if (element is RemoteInfo<Object>) {
      return InfoDisplay(info: element, item: item, model: model);
    }
    if (element is RemoteInput<Object, double> && element.current != null) {
      return SliderInput(
        definition: definition,
        input: element,
        item: item,
        model: model,
        axis: axis,
      );
    }
    if (element is RemoteInput<Object, ({String text, bool submit})>) {
      return TextEntryButton(
        definition: definition,
        input: element,
        item: item,
        model: model,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _button(BuildContext buildContext, RemoteAction<Object> action) {
    final resolved = model.resolve(
      action,
      model.elementContext(item, buildContext: buildContext),
    );
    if (resolved == null) {
      return const ActionButton(
        label: 'Unavailable',
        icon: Icons.block,
        showLabel: false,
      );
    }
    final enabled =
        resolved.enabled &&
        (action.usableOffline || definition.isAvailableOn(model.remote));
    final style = item.elementStyles[action.id];
    return ActionButton(
      key: action.holdable
          ? ObjectKey(model.remote.connection.controller)
          : null,
      appearance: resolved.icon == null
          ? {...item.config, 'showIcon': 'false'}
          : item.config,
      label: action.showLabel
          ? item.config['label'] ?? resolved.label
          : resolved.label,
      icon: resolved.icon ?? Icons.circle,
      elementStyle: style,
      showLabel:
          action.showLabel &&
          style?.showLabel != false &&
          item.config['showLabel'] != 'false',
      repeat:
          action.holdable && (style?.repeat ?? (item.config['hold'] == 'true')),
      onPressed: enabled ? resolved.execute : null,
    );
  }
}
