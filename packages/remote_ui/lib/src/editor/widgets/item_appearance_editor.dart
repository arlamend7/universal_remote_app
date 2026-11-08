import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

class ItemAppearanceEditor extends StatelessWidget {
  const ItemAppearanceEditor({
    super.key,
    required this.style,
    required this.onChanged,
  });
  final RemoteItemStyle style;
  final ValueChanged<RemoteItemStyle> onChanged;

  static const _swatches = <int, String>{
    0: 'Theme default',
    0xff243531: 'Forest',
    0xff273147: 'Slate',
    0xff3b2a47: 'Plum',
    0xff4a3320: 'Amber',
  };

  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: const Text('Appearance'),
    children: [
      _background(),
      SwitchListTile(
        title: const Text('Show border'),
        value: style.showBorder,
        onChanged: (enabled) => onChanged(style.copyWith(showBorder: enabled)),
      ),
      if (style.showBorder) ..._borderOptions(),
      SwitchListTile(
        title: const Text('Rounded corners'),
        value: style.isRounded,
        onChanged: (rounded) => onChanged(
          style.copyWith(
            cornerRadius: rounded ? RemoteItemStyle.defaultCornerRadius : 0,
          ),
        ),
      ),
      if (style.isRounded) _radius(),
      SwitchListTile(
        title: const Text('Inset controls'),
        value: style.padding != 0,
        onChanged: (enabled) =>
            onChanged(style.copyWith(padding: enabled ? 4 : 0)),
      ),
      SwitchListTile(
        title: const Text('Dim item'),
        value: style.opacity < 1,
        onChanged: (enabled) =>
            onChanged(style.copyWith(opacity: enabled ? .65 : 1)),
      ),
    ],
  );

  Widget _background() => DropdownButtonFormField<int>(
    initialValue: style.background ?? 0,
    decoration: const InputDecoration(labelText: 'Item background'),
    items: _items(style.background),
    onChanged: (value) => onChanged(
      style.copyWith(
        background: value == 0 ? null : value,
        foreground: value == null || value == 0 ? null : 0xffffffff,
      ),
    ),
  );

  List<Widget> _borderOptions() => [
    DropdownButtonFormField<int>(
      initialValue: style.borderColor ?? 0,
      decoration: const InputDecoration(labelText: 'Border color'),
      items: _items(style.borderColor, defaultLabel: 'Theme outline'),
      onChanged: (value) =>
          onChanged(style.copyWith(borderColor: value == 0 ? null : value)),
    ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('Border width ${style.borderWidth.toStringAsFixed(0)}'),
      subtitle: Slider(
        value: style.borderWidth,
        min: 1,
        max: 4,
        divisions: 3,
        onChanged: (value) => onChanged(style.copyWith(borderWidth: value)),
      ),
    ),
  ];

  Widget _radius() => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text('Corner radius ${style.cornerRadius.round()}'),
    subtitle: Slider(
      value: style.cornerRadius.clamp(4, 28),
      min: 4,
      max: 28,
      divisions: 12,
      onChanged: (value) => onChanged(style.copyWith(cornerRadius: value)),
    ),
  );

  List<DropdownMenuItem<int>> _items(
    int? current, {
    String defaultLabel = 'Theme default',
  }) => [
    if (current != null && !_swatches.containsKey(current))
      DropdownMenuItem(value: current, child: const Text('Saved color')),
    for (final swatch in _swatches.entries)
      DropdownMenuItem(
        value: swatch.key,
        child: Text(swatch.key == 0 ? defaultLabel : swatch.value),
      ),
  ];
}
