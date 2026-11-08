import 'package:flutter/material.dart';

import '../apps/tv_app_icon.dart';

class ChoiceItems extends StatelessWidget {
  const ChoiceItems({
    super.key,
    required this.choices,
    required this.grid,
    this.selectedId,
  });
  final List<(String, String)> choices;
  final bool grid;
  final String? selectedId;
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
    onTap: () => Navigator.pop(context, choice.$1),
  );
  Widget _app(BuildContext context, (String, String) choice) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () => Navigator.pop(context, choice.$1),
    child: Padding(padding: const EdgeInsets.all(8), child: _appLabel(choice)),
  );
  Widget _appLabel((String, String) choice) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      TvAppIcon(appId: choice.$1, name: choice.$2, size: 36),
      const SizedBox(height: 12),
      Text(
        choice.$2,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    ],
  );
}
