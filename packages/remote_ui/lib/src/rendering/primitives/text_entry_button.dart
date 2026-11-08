import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../modals/text_entry_sheet.dart';
import '../viewmodels/grid_remote_viewmodel.dart';
import 'action_button.dart';

/// A text [RemoteInput] shown as a button that opens the text-entry sheet and
/// commits what the user typed, if the same session is still connected.
class TextEntryButton extends StatelessWidget {
  const TextEntryButton({
    super.key,
    required this.definition,
    required this.input,
    required this.item,
    required this.model,
  });
  final RemoteItemDefinition<Object> definition;
  final RemoteInput<Object, ({String text, bool submit})> input;
  final GridItem item;
  final GridRemoteViewModel model;

  @override
  Widget build(BuildContext context) {
    final elementContext = model.elementContext(item);
    return ActionButton(
      appearance: item.config,
      label: item.config['label'] ?? definition.name,
      icon: input.icon!(elementContext),
      showLabel: item.config['showLabel'] != 'false',
      onPressed: definition.isAvailableOn(model.remote)
          ? () => _enter(context)
          : null,
    );
  }

  Future<void> _enter(BuildContext context) async {
    final owner = model.remote.connection.controller;
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (_) => const TextEntrySheet(),
    );
    if (text == null || !identical(model.remote.connection.controller, owner)) {
      return;
    }
    final submit = definition.setting('submitAfterTyping').isOn(item.config);
    await model.commitInput(input, (text: text, submit: submit));
  }
}
