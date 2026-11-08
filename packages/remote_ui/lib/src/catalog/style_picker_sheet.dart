import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/src/ui_model.dart';

import 'catalog_preview_card.dart';

/// The alternative looks of one control, each drawn with the same sample
/// preview as the add-control library. Pops with the chosen definition id.
class StylePickerSheet extends StatelessWidget {
  const StylePickerSheet({
    super.key,
    required this.choices,
    required this.selectedId,
    required this.dependencies,
    required this.device,
  });
  final List<RemoteItemDefinition<Object>> choices;
  final String selectedId;
  final RemoteEditorHost dependencies;
  final RemoteDevice device;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .75,
      child: Column(
        children: [
          ListTile(
            title: const Text('Choose a style'),
            trailing: IconButton(
              tooltip: 'Close styles',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ),
          Expanded(child: _grid(context)),
        ],
      ),
    ),
  );

  Widget _grid(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisExtent: 156,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    ),
    itemCount: choices.length,
    itemBuilder: (_, index) => CatalogPreviewCard(
      definition: choices[index],
      dependencies: dependencies,
      device: device,
      actionLabel: 'Use',
      selected: choices[index].id == selectedId,
      onAdd: () => Navigator.pop(context, choices[index].id),
    ),
  );
}
