import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../widgets/sheets/app_sheet.dart';
import 'catalog_preview_card.dart';
import 'widget_library_sheet.dart';

class WidgetLibraryState extends State<WidgetLibrarySheet> {
  late final _changes = Listenable.merge([
    widget.dependencies.live.connection.revision,
    widget.dependencies.live.connection.state,
    widget.dependencies.live.profiles,
  ]);
  String query = '';
  @override
  Widget build(BuildContext context) => AppSheet(
    title: 'Add a control',
    subtitle: 'Choose a compatible control for this device.',
    closeLabel: 'Close library',
    scrollable: false,
    child: _body(context),
  );

  Widget _body(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .80,
    child: Column(
      children: [
        _search(),
        Expanded(child: _catalog()),
      ],
    ),
  );
  Widget _search() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Search controls…',
      ),
      onChanged: (value) => setState(() => query = value),
    ),
  );
  Widget _catalog() =>
      ListenableBuilder(listenable: _changes, builder: (_, _) => _results());

  Widget _results() {
    final capabilities = widget.dependencies.capabilitiesFor(
      widget.model.device,
    );
    final choices = RemoteItemRegistry.search(
      capabilities: capabilities,
      query: query,
      where: _fits,
    );
    if (choices.isEmpty) {
      return const Center(
        child: Text(
          'No matching controls. Connect to the device for more options.',
        ),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 156,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: choices.length,
      itemBuilder: (_, index) => _preview(choices[index]),
    );
  }

  bool _fits(RemoteItemDefinition<Object> definition) =>
      (!widget.insideGroup || definition.layout is! GroupLayout) &&
      definition.minimumWidth <= widget.model.columns &&
      definition.minimumHeight <=
          widget.model.maxRows - widget.model.reservedRows;

  Widget _preview(RemoteItemDefinition<Object> definition) =>
      CatalogPreviewCard(
        definition: definition,
        dependencies: widget.dependencies,
        device: widget.model.device,
        onAdd: () => Navigator.pop(context, definition.id),
      );
}
