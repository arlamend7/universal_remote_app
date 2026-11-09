import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../widgets/sheets/app_sheet.dart';
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
  Widget build(BuildContext context) => AppSheet(
    title: 'Choose a style',
    closeLabel: 'Close styles',
    scrollable: false,
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .68,
      child: _grid(context),
    ),
  );

  Widget _grid(BuildContext context) => GridView.builder(
    padding: EdgeInsets.zero,
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
