import 'package:flutter/material.dart';

import '../../widgets/theme/remote_tabs_theme.dart';

class EditorTabs extends StatelessWidget {
  const EditorTabs({
    super.key,
    required this.first,
    required this.second,
    required this.showSecond,
    required this.onChanged,
    this.firstIcon,
    this.secondIcon,
  });

  final String first, second;
  final bool showSecond;
  final ValueChanged<bool> onChanged;
  final IconData? firstIcon, secondIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<RemoteTabsTheme>();
    return DecoratedBox(
      decoration: theme?.track ?? const BoxDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          spacing: 4,
          children: [
            Expanded(child: _tab(context, first, firstIcon, false)),
            Expanded(child: _tab(context, second, secondIcon, true)),
          ],
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, String label, IconData? icon, bool second) {
    final selected = showSecond == second;
    final theme = Theme.of(context).extension<RemoteTabsTheme>();
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 6,
      children: [
        if (icon != null) Icon(icon, size: 17),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
    void select() => onChanged(second);

    return Semantics(
      selected: selected,
      child: selected
          ? FilledButton(
              style: theme?.selected,
              onPressed: select,
              child: content,
            )
          : TextButton(
              style: theme?.unselected,
              onPressed: select,
              child: content,
            ),
    );
  }
}
