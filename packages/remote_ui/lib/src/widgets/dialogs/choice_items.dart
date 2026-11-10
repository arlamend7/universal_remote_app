import 'package:flutter/material.dart';

import '../apps/tv_app_icon.dart';
import '../apps/reported_app_artwork.dart';

class ChoiceItems extends StatelessWidget {
  const ChoiceItems({
    super.key,
    required this.choices,
    required this.grid,
    this.selectedId,
    this.artwork = const {},
    this.readOnly = false,
  });
  final List<(String, String)> choices;
  final bool grid;
  final String? selectedId;
  final Map<String, Uri> artwork;
  final bool readOnly;
  @override
  Widget build(BuildContext context) {
    if (choices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No items reported by this TV.'),
      );
    }
    if (grid) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: .9,
        children: choices.map((choice) => _app(context, choice)).toList(),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: choices.map((choice) => _row(context, choice)).toList(),
    );
  }

  Widget _row(BuildContext context, (String, String) choice) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(choice.$1 == '@add-tv' ? Icons.add : Icons.tv_outlined),
    title: Text(choice.$2),
    trailing: choice.$1 == selectedId ? const Icon(Icons.check) : null,
    onTap: readOnly ? null : () => Navigator.pop(context, choice.$1),
  );
  Widget _app(BuildContext context, (String, String) choice) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: readOnly ? null : () => Navigator.pop(context, choice.$1),
    child: Padding(padding: const EdgeInsets.all(8), child: _appLabel(choice)),
  );
  Widget _appLabel((String, String) choice) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: 12,
    children: [
      _artwork(choice),
      Text(
        choice.$2,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    ],
  );
  Widget _artwork((String, String) choice) {
    final fallback = TvAppIcon(appId: choice.$1, name: choice.$2, size: 36);
    final uri = artwork[choice.$1];
    return uri == null
        ? fallback
        : ReportedAppArtwork(key: ValueKey(uri), uri: uri, fallback: fallback);
  }
}
