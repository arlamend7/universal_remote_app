import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/src/ui_model.dart';

import 'catalog_preview_card_state.dart';

class CatalogPreviewCard extends StatefulWidget {
  const CatalogPreviewCard({
    super.key,
    required this.definition,
    required this.dependencies,
    required this.device,
    required this.onAdd,
  });

  final RemoteItemDefinition<Object> definition;
  final RemoteEditorHost dependencies;
  final RemoteDevice device;
  final VoidCallback onAdd;

  @override
  State<CatalogPreviewCard> createState() => CatalogPreviewCardState();
}
