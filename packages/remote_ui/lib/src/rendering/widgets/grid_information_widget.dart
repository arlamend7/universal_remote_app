import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../../items/standard_items.dart';
import '../viewmodels/grid_remote_viewmodel.dart';
import 'grid_button.dart';

/// Renders any registered [RemoteInfo] the same way: leading visual, title,
/// subtitle. Only the item kind decides which parts are shown.
class GridInformationWidget extends StatelessWidget {
  const GridInformationWidget({
    super.key,
    required this.item,
    required this.model,
  });
  final GridItem item;
  final GridRemoteViewModel model;

  bool get _isActivity =>
      item.kind == GridWidgetKind.currentActivity ||
      item.kind == GridWidgetKind.currentApp;

  @override
  Widget build(BuildContext context) {
    if (item.kind == GridWidgetKind.deviceSwitcher) {
      return _switcher(context);
    }
    if (model.remote.offline && _isActivity) {
      return const SizedBox.expand();
    }
    if (item.kind == GridWidgetKind.currentInput) {
      return _currentInput();
    }
    return _reading(_info.read(_context));
  }

  RemoteElementContext get _context => model.elementContext(item.kind);

  RemoteInfo<Object> get _info =>
      RemoteItemRegistry.resolve(item.kind).elements
          .whereType<RemoteInfo<Object>>()
          .first;

  Widget _switcher(BuildContext context) {
    final action = item.element(deviceSwitchAction);
    return GridButton(
      appearance: item.config,
      label: item.config['label'] ?? 'Switch TV',
      icon: model.iconOf(action, item.kind),
      onPressed: () => action.onPressed(model.remote, context),
    );
  }

  Widget _currentInput() {
    final source = model.tv(RemoteCapability.currentInput);
    return StreamBuilder<DeviceInput?>(
      key: ObjectKey(source),
      stream: source?.currentInputChanges,
      initialData: source?.currentInput,
      builder: (_, snapshot) => _reading(
        RemoteReading(snapshot.data?.name ?? 'Current input unavailable'),
      ),
    );
  }

  Widget _reading(RemoteReading reading) {
    final text = _text(reading);
    final leading = _isActivity ? reading.leading : null;
    if (leading == null) {
      return text;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        leading,
        const SizedBox(width: 6),
        Flexible(child: text),
      ],
    );
  }

  Widget _text(RemoteReading reading) {
    final subtitle = item.kind == GridWidgetKind.currentActivity
        ? reading.subtitle
        : null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: _line(item.config['label'] ?? reading.title)),
        if (subtitle != null) Flexible(child: _line(subtitle)),
      ],
    );
  }

  Widget _line(String value) => Text(
    value,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.center,
  );
}
