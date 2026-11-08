import 'package:flutter/widgets.dart' show Axis;
import 'package:remote_core/remote_core.dart';

import '../host/remote_panel.dart';
import '../layout/models/enums/grid_widget_kind.dart';

/// Everything an element may inspect: the full remote panel and its device.
final class RemoteElementContext {
  const RemoteElementContext({
    required this.kind,
    required this.remote,
    this.position = Axis.horizontal,
  });

  final GridWidgetKind kind;
  final RemotePanel remote;
  final Axis position;

  /// The stored device profile (name, endpoints, metadata) when one is selected.
  RemoteDevice? get device => remote.device;
}
