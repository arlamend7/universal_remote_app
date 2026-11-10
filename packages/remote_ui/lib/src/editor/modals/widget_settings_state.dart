import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../widgets/item_appearance_editor.dart';
import '../../widgets/sheets/app_sheet.dart';
import '../../widgets/sheets/app_sheet_actions.dart';
import '../../widgets/dialogs/device_choice_sheet.dart';
import '../widgets/control_preview_card.dart';
import '../widgets/control_size_picker.dart';
import '../widgets/control_style_picker.dart';
import '../viewmodels/widget_target_choices.dart';
import 'widget_settings_sheet.dart';

/// The form for one placed item. Everything specific to the item comes from
/// its registered definition: its layout, elements and declared settings.
class WidgetSettingsState extends State<WidgetSettingsSheet> {
  late String definitionId = widget.item.definitionId;
  late RemoteItemStyle style = widget.item.style;
  late final elementStyles = {...widget.item.elementStyles};
  late int quarterTurns = widget.item.quarterTurns;
  late int width = widget.item.w, height = widget.item.h;
  late final label = TextEditingController(text: widget.item.config['label']);
  late final settings = {...widget.item.config};
  final _numbers = <String, TextEditingController>{};
  late final targets = widgetTargets(widget.item.config['targets']);
  late final _choices = WidgetTargetChoices(
    widget.dependencies,
    widget.model.device,
  );
  late bool showLabel = widget.item.config['showLabel'] != 'false';
  late bool showIcon = widget.item.config['showIcon'] != 'false';
  late bool hold = widget.item.config['hold'] == 'true';
  String? error;
  bool loading = false;

  RemoteItemDefinition<Object> get _definition =>
      RemoteItemRegistry.resolve(definitionId);
  RemoteItemLayout get _layout => _definition.layout;
  bool get _isGroup => _layout is GroupLayout;
  List<RemoteAction<Object>> get _pressable =>
      _definition.elements.whereType<RemoteAction<Object>>().toList();
  bool get _holdable => _pressable.any((action) => action.holdable);
  CollectionPresentation? get _presentation => switch (_layout) {
    CollectionLayout(:final presentation) => presentation,
    _ => null,
  };
  bool get _hasTargetPicker => _presentation?.choosesTargets ?? false;
  bool get _choosesTargets => _hasTargetPicker;

  @override
  void dispose() {
    label.dispose();
    for (final controller in _numbers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppSheet(
    title: 'Edit control',
    child: _form(),
    footer: AppSheetActions(
      primary: FilledButton(
        onPressed: loading ? null : () => _apply(),
        child: const Text('Done'),
      ),
    ),
  );

  GridItem get draft => widget.item.copy(
    definitionId: definitionId,
    w: width,
    h: height,
    quarterTurns: quarterTurns,
    style: style,
    elementStyles: elementStyles,
    config: _configuration(),
  );

  Map<String, String> _configuration() {
    final text = label.text.trim();
    return {
      for (final setting in _definition.settings)
        setting.key: _numbers[setting.key]?.text ?? setting.read(settings),
      if (text.isNotEmpty) 'label': text,
      'showLabel': '$showLabel',
      'showIcon': '$showIcon',
      if (_holdable) 'hold': '$hold',
      if (_hasTargetPicker) 'targets': encodeWidgetTargets(targets),
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
        definitionId: definitionId,
        columns: widget.model.columns,
        onChanged: _style,
        capabilities: widget.dependencies.capabilitiesFor(widget.model.device),
        dependencies: widget.dependencies,
        device: widget.model.device,
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
      if (!_isGroup)
        TextButton.icon(
          onPressed: height <= widget.model.columns && height <= 4
              ? _rotate
              : null,
          icon: const Icon(Icons.rotate_right),
          label: Text('Rotate · ${quarterTurns * 90}°'),
        ),
      ItemAppearanceEditor(
        style: style,
        onChanged: (next) => setState(() => style = next),
      ),
      if (_pressable.isNotEmpty) _largerIcons(),
      for (final setting in _definition.settings) _setting(setting),
      if (_choosesTargets) _targets(),
      if (_isGroup)
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
      Wrap(
        alignment: WrapAlignment.center,
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
    controller: label,
    decoration: const InputDecoration(labelText: 'Name (optional)'),
    onChanged: (_) => setState(() {}),
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
      if (_holdable)
        SwitchListTile(
          title: const Text('Keep repeating when held'),
          value: hold,
          onChanged: (v) => setState(() => hold = v),
        ),
    ],
  );

  void _rotate() => setState(() {
    final previousWidth = width;
    width = height;
    height = previousWidth;
    quarterTurns = (quarterTurns + 1) % 4;
  });

  Widget _largerIcons() => SwitchListTile(
    title: const Text('Larger icons'),
    value: _pressable.every(
      (element) => (elementStyles[element.id]?.iconSize ?? 24) > 24,
    ),
    onChanged: (enabled) => setState(() {
      for (final element in _pressable) {
        elementStyles[element.id] = RemoteElementStyle(
          iconSize: enabled ? 32 : 24,
          foreground: elementStyles[element.id]?.foreground,
        );
      }
    }),
  );

  void _style(String next) => setState(() {
    quarterTurns = 0;
    definitionId = next;
    final definition = RemoteItemRegistry.resolve(next);
    width = definition.width.clamp(
      definition.minimumWidth,
      widget.model.columns,
    );
    height = definition.height;
  });

  Widget _setting(RemoteSetting setting) => switch (setting.type) {
    RemoteSettingType.toggle => SwitchListTile(
      title: Text(setting.label),
      value: setting.isOn(settings),
      onChanged: (value) => setState(() => settings[setting.key] = '$value'),
    ),
    RemoteSettingType.number || RemoteSettingType.text => TextField(
      controller: _numbers.putIfAbsent(
        setting.key,
        () => TextEditingController(text: setting.read(settings)),
      ),
      keyboardType: setting.type == RemoteSettingType.number
          ? TextInputType.number
          : TextInputType.url,
      autocorrect: false,
      decoration: InputDecoration(labelText: setting.label),
    ),
    RemoteSettingType.slider => Column(
      children: [
        Text(setting.label),
        Slider(
          value: setting.number(settings),
          min: setting.minimum.toDouble(),
          max: setting.maximum.toDouble(),
          divisions: setting.divisions,
          label: setting.number(settings).toStringAsFixed(2),
          onChanged: (value) =>
              setState(() => settings[setting.key] = '$value'),
        ),
      ],
    ),
  };

  Widget _targets() => Column(
    children: [
      for (var index = 0; index < targets.length; index++) _targetRow(index),
      TextButton.icon(
        onPressed: loading ? null : _choose,
        icon: const Icon(Icons.add),
        label: Text(
          loading ? 'Loading…' : 'Choose ${_definition.category.label}',
        ),
      ),
    ],
  );

  Widget _targetRow(int index) {
    final target = targets[index];
    final choices = _choices.cached(definitionId);
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
      final choices = await _choices.load(definitionId);
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
    setState(() {
      if (_presentation?.isSingle ?? false) {
        targets.clear();
      }
      targets.removeWhere((item) => item.$1 == target.$1);
      targets.add(target);
    });
  }

  String? _problem() {
    if (!showIcon && !showLabel) {
      return 'Keep an icon or a name so you can recognize this control.';
    }
    for (final setting in _definition.settings) {
      final problem = setting.problem(
        _numbers[setting.key]?.text ?? setting.read(settings),
      );
      if (problem != null) {
        return problem;
      }
    }
    return null;
  }

  bool _apply({bool close = true}) {
    final problem = _problem();
    if (problem != null) {
      setState(() => error = problem);
      return false;
    }
    final titled =
        _isGroup &&
        settings['showTitle'] == 'true' &&
        widget.item.config['showTitle'] != 'true';
    final children = titled
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
