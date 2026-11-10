import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../../catalog/style_picker_sheet.dart';
import '../../rendering/viewmodels/grid_remote_viewmodel.dart';
import '../../widgets/sheets/app_sheet.dart';
import '../../widgets/sheets/app_sheet_actions.dart';
import '../../widgets/sheets/show_app_sheet.dart';
import '../../widgets/dialogs/device_choice_sheet.dart';
import '../widgets/control_draft_preview.dart';
import '../widgets/border_shape_picker.dart';
import '../widgets/border_size_picker.dart';
import '../widgets/editor_number_field.dart';
import '../widgets/editor_tabs.dart';
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
  late final settings = {...widget.item.config};
  final _numbers = <String, TextEditingController>{};
  late final targets = widgetTargets(widget.item.config['targets']);
  late final _choices = WidgetTargetChoices(
    widget.dependencies,
    widget.model.device,
  );
  String? error;
  bool loading = false;
  bool itemTab = false;
  int stepRevision = 0;

  RemoteItemDefinition<Object> get _definition =>
      RemoteItemRegistry.resolve(definitionId);
  RemoteItemLayout get _layout => _definition.layout;
  bool get _isGroup => _layout is GroupLayout;
  CollectionPresentation? get _presentation => switch (_layout) {
    CollectionLayout(:final presentation) => presentation,
    _ => null,
  };
  bool get _hasTargetPicker => _presentation?.choosesTargets ?? false;
  bool get _appCollection =>
      _definition.category == RemoteItemCategory.pinnedApps && _hasTargetPicker;
  bool get _editsAppEntries =>
      _appCollection && _presentation?.isSingle == false;
  bool get _hasTabs =>
      _editsAppEntries || _definition.elements.where(_editable).length > 1;

  RemoteCollection<Object, Object>? get _collection => _definition.elements
      .whereType<RemoteCollection<Object, Object>>()
      .firstOrNull;

  @override
  void dispose() {
    for (final controller in _numbers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppSheet(
    title: 'Edit Control',
    heightFactor: 1,
    horizontalInset: 12,
    scrollable: false,
    child: LayoutBuilder(builder: _form),
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

  Map<String, String> _configuration() => {
    ...settings,
    for (final setting in _definition.settings)
      setting.key: _numbers[setting.key]?.text ?? setting.read(settings),
    if (_hasTargetPicker)
      'targets': encodeWidgetTargets(
        _presentation?.isSingle == true ? targets.take(1).toList() : targets,
      ),
  };

  Widget _form(BuildContext context, BoxConstraints constraints) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      ControlDraftPreview(
        item: draft.copy(w: width.clamp(1, 16), h: height.clamp(1, 16)),
        dependencies: widget.dependencies,
        device: widget.model.device,
        height: (constraints.maxHeight * .28).clamp(0.0, 180.0),
      ),
      _variants(),
      if (_hasTabs) _tabs(),
      Expanded(child: _tabContent()),
      if (error != null)
        Text(
          error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
    ],
  );

  Widget _variants() {
    final capabilities = widget.dependencies.capabilitiesFor(
      widget.model.device,
    );
    final originalId = widget.item.definitionId;
    final choices = RemoteItemRegistry.variations(definitionId)
        .where(
          (item) =>
              item.id == originalId ||
              item.id == definitionId ||
              item.isCompatibleWith(capabilities),
        )
        .toList();
    if (choices.length < 2) {
      return const SizedBox.shrink();
    }
    return InkWell(
      key: const ValueKey('control-variants'),
      borderRadius: BorderRadius.circular(12),
      onTap: loading ? null : () => _chooseVariant(choices),
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Style', isDense: true),
        child: Row(
          children: [
            Expanded(
              child: Text(_definition.name, overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseVariant(
    List<RemoteItemDefinition<Object>> choices,
  ) async {
    final id = await showAppModal<String>(
      context,
      builder: (_) => StylePickerSheet(
        choices: choices,
        selectedId: definitionId,
        dependencies: widget.dependencies,
        device: widget.model.device,
      ),
    );
    if (!mounted || id == null || id == definitionId) {
      return;
    }
    _changeVariant(RemoteItemRegistry.resolve(id));
  }

  void _changeVariant(RemoteItemDefinition<Object> choice) {
    final keepSize = choice.accepts(draft.contentWidth, draft.contentHeight);
    setState(() {
      definitionId = choice.id;
      if (!keepSize) {
        width = choice.width;
        height = choice.height;
        quarterTurns = 0;
      }
      error = null;
    });
  }

  Widget _tabs() => EditorTabs(
    first: 'Element',
    second: 'Item Configuration',
    showSecond: itemTab,
    onChanged: (value) => setState(() => itemTab = value),
  );

  Widget _tabContent() => ListView(
    key: PageStorageKey((_hasTabs, itemTab)),
    padding: const EdgeInsets.only(bottom: 8),
    children: [
      for (final section in _sections())
        Padding(padding: const EdgeInsets.only(bottom: 12), child: section),
    ],
  );

  List<Widget> _sections() {
    if (!_hasTabs) {
      return [..._itemSections(), ..._elementSections()];
    }
    return itemTab ? _itemSections() : _elementSections();
  }

  List<Widget> _elementSections() => [
    _section('Layout', Icons.grid_view, [
      _dimension('Width', horizontal: true),
      _dimension('Height', horizontal: false),
      if (!_isGroup) _rotation(),
    ], expanded: true),
    _section('Border', Icons.border_outer, [
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: BorderSizePicker(
          width: style.showBorder ? style.borderWidth : 0,
          onChanged: (value) => _appearance(
            style.copyWith(
              showBorder: value > 0,
              borderWidth: value > 0 ? value : style.borderWidth,
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: BorderShapePicker(
          radius: style.cornerRadius,
          onChanged: (value) => _appearance(style.copyWith(cornerRadius: value)),
        ),
      ),
    ], expanded: true),
  ];

  Widget _section(
    String title,
    IconData icon,
    List<Widget> children, {
    bool expanded = false,
    String? id,
  }) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey(id ?? title),
        shape: const Border(),
        collapsedShape: const Border(),
        textColor: theme.colorScheme.onSurface,
        iconColor: theme.colorScheme.primary,
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Icon(icon, size: 20, color: theme.colorScheme.primary),
        initiallyExpanded: expanded,
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: children,
      ),
    );
  }

  Widget _dimension(String label, {required bool horizontal}) {
    return EditorNumberField(
      label: label,
      value: horizontal ? width : height,
      minimum: 1,
      maximum: 16,
      onChanged: (value) => _size(
        horizontal ? value : width,
        horizontal ? height : value,
        quarterTurns,
      ),
    );
  }

  Widget _rotation() =>
      EditorNumberField.rotation(value: quarterTurns, onChanged: _rotate);

  void _rotate(int turn) {
    final swap = (turn - quarterTurns).isOdd;
    _size(swap ? height : width, swap ? width : height, turn);
  }

  void _size(int w, int h, int turn) {
    setState(() {
      width = w;
      height = h;
      quarterTurns = turn;
      error = null;
    });
  }

  void _appearance(RemoteItemStyle next) => setState(() {
    style = next;
    error = null;
  });

  List<Widget> _itemSections() => [
    if (_definition.settings.isNotEmpty || _hasTargetPicker || _isGroup)
      _section('Control options', Icons.tune, [
        for (final setting in _definition.settings) _setting(setting),
        if (_hasTargetPicker) _targets(),
        if (_isGroup)
          TextButton.icon(
            onPressed: _editGroup,
            icon: const Icon(Icons.dashboard_customize_outlined),
            label: const Text('Edit controls in this group'),
          ),
      ], expanded: true),
    if (_editsAppEntries)
      for (var index = 0; index < targets.length; index++) _appEntry(index),
    for (final element in _definition.elements.where(_editable))
      if (element is! RemoteCollection<Object, Object>)
        ..._elementSettings(element),
    if (_appCollection && !_editsAppEntries && targets.isNotEmpty)
      _section(
        'Display',
        Icons.visibility_outlined,
        _appDisplay(_collection!.id),
        expanded: true,
      ),
  ];

  List<Widget> _elementSettings(RemoteElement<Object> element) {
    final appearance = elementStyles[element.id] ?? const RemoteElementStyle();
    final display = _displaySettings(element, appearance);
    if (!_hasTabs) {
      return display.isEmpty
          ? []
          : [
              _section(
                'Display',
                Icons.visibility_outlined,
                display,
                expanded: true,
              ),
            ];
    }
    return [_childSection(element, appearance, display)];
  }

  List<Widget> _displaySettings(
    RemoteElement<Object> element,
    RemoteElementStyle appearance,
  ) => [
    if (element is RemoteInfo<Object>) ..._infoSettings(element, appearance),
    if (element is RemoteAction<Object>)
      ..._buttonSettings(element, appearance),
  ];

  Widget _appEntry(int index) {
    final target = targets[index];
    final key = _collection!.entryStyleKey(target.$1);
    final appearance = elementStyles[key] ?? const RemoteElementStyle();
    return _section(target.$2, Icons.apps, [
      if (_missingTarget(target.$1)) const Text('Unavailable on this TV'),
      _settingHeading('Display'),
      ..._appDisplay(key),
      _settingHeading('Border'),
      ..._itemBorder(key, appearance),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: _targetActions(index, target.$2),
      ),
    ], id: key);
  }

  List<Widget> _appDisplay(String key) {
    final style = elementStyles[key] ?? const RemoteElementStyle();
    final label =
        style.showLabel ??
        (_presentation != CollectionPresentation.icon &&
            settings['showLabel'] != 'false');
    final icon =
        !label || (style.showIcon ?? (settings['showIcon'] != 'false'));
    return [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Show label'),
        value: label,
        onChanged: icon
            ? (value) => _childStyle(key, style.copyWith(showLabel: value))
            : null,
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Show icon'),
        value: icon,
        onChanged: label
            ? (value) => _childStyle(key, style.copyWith(showIcon: value))
            : null,
      ),
    ];
  }

  List<Widget> _itemBorder(String id, RemoteElementStyle appearance) => [
    Padding(
      padding: const EdgeInsets.only(top: 12),
      child: BorderSizePicker(
        width: appearance.borderWidth,
        onChanged: (value) =>
            _childStyle(id, appearance.copyWith(borderWidth: value)),
      ),
    ),
    Padding(
      padding: const EdgeInsets.only(top: 12),
      child: BorderShapePicker(
        radius: appearance.cornerRadius,
        onChanged: (value) =>
            _childStyle(id, appearance.copyWith(cornerRadius: value)),
      ),
    ),
  ];

  bool _editable(RemoteElement<Object> element) {
    if (_layout is TouchSurfaceLayout || _layout is DialLayout) {
      return element is! RemoteAction<Object>;
    }
    return true;
  }

  Widget _childSection(
    RemoteElement<Object> element,
    RemoteElementStyle appearance,
    List<Widget> displaySettings,
  ) {
    final model = GridRemoteViewModel(
      widget.dependencies.preview(widget.model.device, sample: true),
    );
    final context = model.elementContext(draft);
    final action = element is RemoteAction<Object>
        ? model.resolve(element, context)
        : null;
    final info = element is RemoteInfo<Object> ? element : null;
    return _section(
      action?.label ?? info?.defaultLabel ?? _elementName(element.id),
      element.icon?.call(context) ?? action?.icon ?? Icons.widgets_outlined,
      [
        if (displaySettings.isNotEmpty) ...[
          _settingHeading('Display'),
          ...displaySettings,
        ],
        _settingHeading('Border'),
        ..._itemBorder(element.id, appearance),
      ],
      id: element.id,
    );
  }

  Widget _settingHeading(String label) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        header: true,
        child: Text(label, style: Theme.of(context).textTheme.titleSmall),
      ),
    ),
  );

  List<Widget> _buttonSettings(
    RemoteAction<Object> action,
    RemoteElementStyle appearance,
  ) => [
    if (action.showLabel && settings['showLabel'] != 'false')
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Show label'),
        value: appearance.showLabel ?? true,
        onChanged: (value) =>
            _childStyle(action.id, appearance.copyWith(showLabel: value)),
      ),
    if (action.holdable)
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Keep repeating when held'),
        value: appearance.repeat ?? (settings['hold'] == 'true'),
        onChanged: (value) =>
            _childStyle(action.id, appearance.copyWith(repeat: value)),
      ),
  ];

  String _elementName(String id) {
    final name = id.replaceAll('_', ' ');
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  List<Widget> _infoSettings(
    RemoteInfo<Object> info,
    RemoteElementStyle appearance,
  ) => [
    if (info.defaultLabel != null) ...[
      _labelRow(info, appearance),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Show label'),
        value: appearance.showLabel ?? info.showLabelByDefault,
        onChanged: (value) =>
            _childStyle(info.id, appearance.copyWith(showLabel: value)),
      ),
    ],
    if (info.supportsOfflineIndicator)
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Show indicator'),
        subtitle: const Text('Show indicator when offline'),
        value: appearance.showOfflineIndicator,
        onChanged: (value) => _childStyle(
          info.id,
          appearance.copyWith(showOfflineIndicator: value),
        ),
      ),
  ];

  Widget _labelRow(RemoteInfo<Object> info, RemoteElementStyle appearance) =>
      Row(
        spacing: 8,
        children: [
          const Expanded(child: Text('Label')),
          Flexible(child: _labelInput(info, appearance)),
          IconButton(
            tooltip: 'Reset label',
            onPressed: appearance.label == null
                ? null
                : () => _resetLabel(info, appearance),
            icon: const Icon(Icons.restart_alt, size: 20),
          ),
        ],
      );

  Widget _labelInput(RemoteInfo<Object> info, RemoteElementStyle appearance) =>
      Semantics(
        label: 'Label',
        child: TextFormField(
          key: PageStorageKey(('label', info.id, stepRevision)),
          initialValue: appearance.label,
          textAlign: TextAlign.end,
          decoration: InputDecoration(
            hintText: info.defaultLabel,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
          ),
          onChanged: (value) =>
              _childStyle(info.id, appearance.copyWith(label: value.trim())),
        ),
      );

  void _resetLabel(RemoteInfo<Object> info, RemoteElementStyle appearance) {
    stepRevision++;
    _childStyle(info.id, appearance.copyWith(label: ''));
  }

  void _childStyle(String id, RemoteElementStyle appearance) => setState(() {
    elementStyles[id] = appearance;
    error = null;
  });

  Widget _setting(RemoteSetting setting) => switch (setting.type) {
    RemoteSettingType.toggle => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(setting.label),
      value: setting.isOn(settings),
      onChanged: (value) => setState(() => settings[setting.key] = '$value'),
    ),
    RemoteSettingType.number || RemoteSettingType.text => TextField(
      key: PageStorageKey(('setting', setting.key)),
      controller: _numbers.putIfAbsent(
        setting.key,
        () => TextEditingController(text: setting.read(settings)),
      ),
      keyboardType: setting.type == RemoteSettingType.number
          ? TextInputType.number
          : TextInputType.url,
      autocorrect: false,
      decoration: InputDecoration(labelText: setting.label),
      onChanged: (_) => setState(() {}),
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

  int get _visibleTargets => _presentation?.isSingle == true
      ? targets.length.clamp(0, 1)
      : targets.length;

  Widget _targets() => Column(
    children: [
      if (!_editsAppEntries)
        for (var index = 0; index < _visibleTargets; index++) _targetRow(index),
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
    return ListTile(
      title: Text(target.$2),
      subtitle: _missingTarget(target.$1)
          ? const Text('Unavailable on this TV')
          : null,
      trailing: _targetActions(index, target.$2),
    );
  }

  bool _missingTarget(String id) {
    final choices = _choices.cached(definitionId);
    return choices != null && !choices.any((item) => item.$1 == id);
  }

  Widget _targetActions(int index, String name) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (_visibleTargets > 1) _moveTargetButton(index, -1, name),
      if (_visibleTargets > 1) _moveTargetButton(index, 1, name),
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
    final replacement = draft.copy(children: children);
    if (!widget.model.canReplace(replacement)) {
      setState(() => error = _sizeProblem(replacement));
      return false;
    }
    widget.model.replace(replacement);
    if (widget.model.error != null) {
      setState(() => error = widget.model.error);
      return false;
    }
    if (close) {
      Navigator.pop(context);
    }
    return true;
  }

  String _sizeProblem(GridItem item) {
    if (!_definition.accepts(item.contentWidth, item.contentHeight)) {
      return 'This control does not support ${item.w} × ${item.h} blocks at this rotation.';
    }
    return 'This size overlaps another control or extends past the group or page.';
  }

  void _editGroup() {
    if (_apply()) {
      widget.onEditGroup?.call();
    }
  }
}
