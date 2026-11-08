import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../widgets/structured_input_editor.dart';
import '../widgets/item_appearance_editor.dart';
import '../../widgets/sheets/app_sheet.dart';
import '../../widgets/dialogs/device_choice_sheet.dart';
import '../widgets/control_preview_card.dart';
import '../widgets/control_size_picker.dart';
import '../widgets/control_style_picker.dart';
import '../viewmodels/widget_target_choices.dart';
import 'widget_settings_sheet.dart';

class WidgetSettingsState extends State<WidgetSettingsSheet> {
  late GridWidgetKind kind = widget.item.kind;
  late ItemOrientation orientation = widget.item.orientation;
  late RemoteItemStyle style = widget.item.style;
  late final elementStyles = {...widget.item.elementStyles};
  late TouchpadConfiguration touchpad = TouchpadConfiguration.fromSettings(
    widget.item.config,
  );
  late KeyboardConfiguration keyboard = KeyboardConfiguration.fromSettings(
    widget.item.config,
  );
  late int quarterTurns = widget.item.quarterTurns;
  late int width = widget.item.w, height = widget.item.h;
  late final fields = <String, TextEditingController>{
    'label': TextEditingController(text: widget.item.config['label']),
    'value': TextEditingController(text: widget.item.config['value'] ?? '15'),
    'minutes': TextEditingController(
      text: widget.item.config['minutes'] ?? '30',
    ),
  };
  late final targets = widgetTargets(widget.item.config['targets']);
  late final _choices = WidgetTargetChoices(
    widget.dependencies,
    widget.model.device,
  );
  late bool showLabel = widget.item.config['showLabel'] != 'false';
  late bool showIcon = widget.item.config['showIcon'] != 'false';
  late bool hold = widget.item.config['hold'] == 'true';
  late bool confirm = widget.item.config['confirm'] != 'false';
  late bool showTitle = widget.item.config['showTitle'] == 'true';
  String? error;
  bool loading = false;
  RemoteItemCategory get category => WidgetCatalog.definition(kind).category;
  @override
  void dispose() {
    for (final field in fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AppSheet(title: 'Edit control', child: _form());
  GridItem get draft => widget.item.copy(
    kind: kind,
    w: width,
    h: height,
    quarterTurns: quarterTurns,
    orientation: orientation,
    style: style,
    elementStyles: elementStyles,
    config: _configuration(),
  );
  Map<String, String> _configuration() {
    final config = {...widget.item.config}..remove('label');
    return {
      ...config,
      if (fields['label']!.text.trim().isNotEmpty)
        'label': fields['label']!.text.trim(),
      'showLabel': '$showLabel',
      'showIcon': '$showIcon',
      'hold': '$hold',
      'confirm': '$confirm',
      'showTitle': '$showTitle',
      'value': fields['value']!.text,
      'minutes': fields['minutes']!.text,
      'targets': encodeWidgetTargets(targets),
      if (kind == GridWidgetKind.touchpad) ...touchpad.toSettings(),
      if (kind == GridWidgetKind.keyboard) ...keyboard.toSettings(),
    };
  }

  Widget _form() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      ControlPreviewCard(
        item: draft,
        dependencies: widget.dependencies,
        device: widget.model.device,
      ),
      _name(),
      const SizedBox(height: 16),
      ControlStylePicker(
        kind: kind,
        columns: widget.model.columns,
        onChanged: _style,
        capabilities: widget.dependencies.capabilitiesFor(widget.model.device),
      ),
      const SizedBox(height: 16),
      ControlSizePicker(
        item: draft,
        columns: widget.model.columns,
        onChanged: (w, h) => setState(() {
          width = w;
          height = h;
        }),
      ),
      if (kind != GridWidgetKind.group)
        TextButton.icon(
          onPressed: height <= widget.model.columns && height <= 4
              ? _rotate
              : null,
          icon: const Icon(Icons.rotate_right),
          label: Text('Rotate · ${quarterTurns * 90}°'),
        ),
      if (kind == GridWidgetKind.volumeRocker ||
          kind == GridWidgetKind.volumeHorizontal)
        _orientationPicker(),
      ItemAppearanceEditor(
        style: style,
        onChanged: (next) => setState(() => style = next),
      ),
      ..._elementOptions(),
      StructuredInputEditor(
        kind: kind,
        touchpad: touchpad,
        keyboard: keyboard,
        onTouchpad: (value) => setState(() => touchpad = value),
        onKeyboard: (value) => setState(() => keyboard = value),
      ),
      if (_hasTargets) _targets(),
      if (kind == GridWidgetKind.volumePreset)
        _field('value', 'Volume (0–100)', number: true),
      if (kind == GridWidgetKind.sleep)
        _field('minutes', 'Turn off after this many minutes', number: true),
      if (kind == GridWidgetKind.group)
        TextButton.icon(
          onPressed: _editGroup,
          icon: const Icon(Icons.dashboard_customize_outlined),
          label: const Text('Edit controls in this group'),
        ),
      _more(),
      if (error != null)
        Text(
          error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: loading ? null : () => _apply(),
        child: const Text('Done'),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: loading ? null : _duplicate,
            icon: const Icon(Icons.copy),
            label: const Text('Duplicate'),
          ),
          TextButton.icon(
            onPressed: loading ? null : _remove,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove'),
          ),
        ],
      ),
    ],
  );
  Widget _name() => TextField(
    controller: fields['label'],
    decoration: const InputDecoration(labelText: 'Name (optional)'),
    onChanged: (_) => setState(() {}),
  );
  bool get _hasTargets =>
      kind != GridWidgetKind.apps &&
      kind != GridWidgetKind.inputs &&
      kind != GridWidgetKind.recentApps &&
      RemoteItemRegistry.resolve(kind).elements.any(
        (element) => element is RemoteCollection<TvRemoteDevice, Object>,
      );

  Widget _more() => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: const Text('More options'),
    children: [
      SwitchListTile(
        title: const Text('Show icon'),
        value: showIcon,
        onChanged: (v) => setState(() => showIcon = v),
      ),
      SwitchListTile(
        title: const Text('Show name'),
        value: showLabel,
        onChanged: (v) => setState(() => showLabel = v),
      ),
      if (category == RemoteItemCategory.audio ||
          category == RemoteItemCategory.navigation ||
          category == RemoteItemCategory.channels)
        SwitchListTile(
          title: const Text('Keep repeating when held'),
          value: hold,
          onChanged: (v) => setState(() => hold = v),
        ),
      if (kind == GridWidgetKind.power)
        SwitchListTile(
          title: const Text('Ask before turning off'),
          value: confirm,
          onChanged: (v) => setState(() => confirm = v),
        ),
      if (kind == GridWidgetKind.group)
        SwitchListTile(
          title: const Text('Show group name'),
          value: showTitle,
          onChanged: (v) => setState(() => showTitle = v),
        ),
    ],
  );
  void _rotate() => setState(() {
    final previousWidth = width;
    width = height;
    height = previousWidth;
    quarterTurns = (quarterTurns + 1) % 4;
  });

  List<Widget> _elementOptions() {
    final ids = RemoteItemRegistry.resolve(kind).elements
        .map((element) => element.id);
    return [
      if (ids.contains(TvItems.volumeUp.id))
        _elementSize(TvItems.volumeUp.id, 'Larger volume up icon'),
      if (ids.contains(TvItems.volumeDown.id))
        _elementSize(TvItems.volumeDown.id, 'Larger volume down icon'),
    ];
  }

  Widget _elementSize(String id, String label) => SwitchListTile(
    title: Text(label),
    value: (elementStyles[id]?.iconSize ?? 24) > 24,
    onChanged: (enabled) => setState(() {
      elementStyles[id] = RemoteElementStyle(
        iconSize: enabled ? 32 : 24,
        foreground: elementStyles[id]?.foreground,
      );
    }),
  );

  Widget _orientationPicker() => DropdownButtonFormField<ItemOrientation>(
    initialValue: orientation,
    decoration: const InputDecoration(labelText: 'Control orientation'),
    items: [
      for (final option in ItemOrientation.values)
        DropdownMenuItem(value: option, child: Text(option.name)),
    ],
    onChanged: _orient,
  );

  void _orient(ItemOrientation? value) {
    if (value == null) {
      return;
    }
    setState(() {
      orientation = value;
      final definition = WidgetCatalog.definition(draft.layoutKind);
      final minWidth = quarterTurns.isOdd
          ? definition.minimumHeight
          : definition.minimumWidth;
      final minHeight = quarterTurns.isOdd
          ? definition.minimumWidth
          : definition.minimumHeight;
      if (minWidth <= widget.model.columns) {
        width = width.clamp(minWidth, widget.model.columns);
      }
      height = height.clamp(minHeight, 16);
    });
  }

  void _style(GridWidgetKind next) => setState(() {
    orientation = ItemOrientation.automatic;
    quarterTurns = 0;
    kind = next;
    final definition = WidgetCatalog.definition(next);
    width = definition.width.clamp(
      definition.minimumWidth,
      widget.model.columns,
    );
    height = definition.height;
  });
  Widget _field(String key, String label, {bool number = false}) => TextField(
    controller: fields[key],
    keyboardType: number ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(labelText: label),
  );
  Widget _targets() => Column(
    children: [
      for (var index = 0; index < targets.length; index++) _targetRow(index),
      TextButton.icon(
        onPressed: loading ? null : _choose,
        icon: const Icon(Icons.add),
        label: Text(loading ? 'Loading…' : 'Choose ${category.name}'),
      ),
    ],
  );
  Widget _targetRow(int index) {
    final target = targets[index];
    final choices = _choices.cached(kind);
    final missing =
        choices != null && !choices.any((item) => item.$1 == target.$1);
    return ListTile(
      title: Text(target.$2),
      subtitle: missing ? const Text('Unavailable on this TV') : null,
      trailing: _targetActions(index, target.$2),
    );
  }

  Widget _targetActions(int index, String name) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (targets.length > 1) _moveTargetButton(index, -1, name),
      if (targets.length > 1) _moveTargetButton(index, 1, name),
      IconButton(
        tooltip: 'Remove $name',
        icon: const Icon(Icons.close),
        onPressed: () => setState(() => targets.removeAt(index)),
      ),
    ],
  );

  Widget _moveTargetButton(int index, int direction, String name) {
    final to = index + direction;
    final up = direction < 0;
    return IconButton(
      tooltip: up ? 'Move $name up' : 'Move $name down',
      icon: Icon(up ? Icons.arrow_upward : Icons.arrow_downward),
      onPressed: to < 0 || to >= targets.length
          ? null
          : () => setState(() => targets.insert(to, targets.removeAt(index))),
    );
  }

  Future<void> _choose() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final choices = await _choices.load(kind);
      if (!mounted) {
        return;
      }
      final id = await DeviceChoiceSheet.choose(
        context,
        'Choose shortcut',
        choices,
      );
      if (id != null && mounted) {
        _remember(choices.firstWhere((item) => item.$1 == id));
      }
    } catch (exception) {
      if (mounted) {
        setState(
          () => error = exception is RemoteException
              ? exception.message
              : 'Could not load choices from this TV.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _remember((String, String) target) {
    final single = {
      'appShortcut',
      'appIcon',
      'inputShortcut',
      'channelShortcut',
    }.contains(kind.name);
    setState(() {
      if (single) {
        targets.clear();
      }
      targets.removeWhere((item) => item.$1 == target.$1);
      targets.add(target);
    });
  }

  bool _apply({bool close = true}) {
    if (!showIcon && !showLabel) {
      setState(
        () =>
            error = 'Keep an icon or a name so you can recognize this control.',
      );
      return false;
    }
    final volume = int.tryParse(fields['value']!.text),
        minutes = int.tryParse(fields['minutes']!.text);
    if (volume == null ||
        volume < 0 ||
        volume > 100 ||
        minutes == null ||
        minutes < 1 ||
        minutes > 180) {
      setState(() => error = 'Check the volume or timer value.');
      return false;
    }
    final children = showTitle && widget.item.config['showTitle'] != 'true'
        ? widget.item.children
              .map((child) => child.copy(y: child.y + 1))
              .toList()
        : widget.item.children;
    widget.model.replace(draft.copy(children: children));
    if (widget.model.error != null) {
      setState(() => error = widget.model.error);
      return false;
    }
    if (close) {
      Navigator.pop(context);
    }
    return true;
  }

  void _editGroup() {
    if (_apply()) {
      widget.onEditGroup?.call();
    }
  }

  void _duplicate() {
    if (_apply()) {
      widget.model.duplicate(widget.model.selection ?? draft);
    }
  }

  void _remove() {
    widget.model.remove(widget.item.id);
    Navigator.pop(context);
  }
}
