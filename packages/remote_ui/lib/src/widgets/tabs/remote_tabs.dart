import 'package:flutter/material.dart';

import '../theme/remote_tabs_theme.dart';

class RemoteTabs<T> extends StatelessWidget {
  const RemoteTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  final List<({T value, String label, IconData? icon})> tabs;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<RemoteTabsTheme>();
    return DecoratedBox(
      decoration: theme?.track ?? const BoxDecoration(),
      child: Padding(
        padding: theme?.padding ?? EdgeInsets.zero,
        child: Row(
          spacing: theme?.spacing ?? 0,
          children: [for (final tab in tabs) Expanded(child: _tab(tab, theme))],
        ),
      ),
    );
  }

  Widget _tab(
    ({T value, String label, IconData? icon}) tab,
    RemoteTabsTheme? theme,
  ) {
    final isSelected = selected == tab.value;
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: theme?.iconSpacing ?? 0,
      children: [
        if (tab.icon != null) Icon(tab.icon, size: theme?.iconSize),
        Flexible(child: Text(tab.label, textAlign: TextAlign.center)),
      ],
    );
    void select() => onChanged(tab.value);

    return Semantics(
      selected: isSelected,
      child: isSelected
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
