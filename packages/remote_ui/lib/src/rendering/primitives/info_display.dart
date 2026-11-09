import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../viewmodels/grid_remote_viewmodel.dart';

/// Draws a [RemoteInfo]: optional leading visual, title and subtitle. The
/// element decides what is read, whether the device streams it, and whether it
/// hides while disconnected.
class InfoDisplay extends StatelessWidget {
  const InfoDisplay({
    super.key,
    required this.info,
    required this.item,
    required this.model,
  });
  final RemoteInfo<Object> info;
  final GridItem item;
  final GridRemoteViewModel model;

  RemoteElementContext get _context => model.elementContext(item);

  @override
  Widget build(BuildContext context) {
    if (info.hiddenWhenOffline && model.remote.offline) {
      return const SizedBox.expand();
    }
    final stream = info.watch?.call(_context);
    if (stream == null) {
      return _reading(info.read(_context));
    }
    return StreamBuilder<RemoteReading>(
      key: ObjectKey(model.remote.connection.controller),
      stream: stream,
      initialData: info.read(_context),
      builder: (_, snapshot) => _reading(snapshot.data ?? info.read(_context)),
    );
  }

  Widget _reading(RemoteReading reading) {
    final text = _text(reading);
    final leading = reading.leading;
    final content = leading == null
        ? text
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [
              leading,
              Flexible(child: text),
            ],
          );
    return Semantics(label: reading.semanticsLabel, child: content);
  }

  Widget _text(RemoteReading reading) {
    final subtitle = reading.subtitle;
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
