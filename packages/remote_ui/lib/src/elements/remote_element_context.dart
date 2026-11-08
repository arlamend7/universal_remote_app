import 'package:flutter/widgets.dart' show BuildContext;
import 'package:remote_core/remote_core.dart';

import '../host/remote_panel.dart';

/// Everything an element may inspect: the full remote panel and its device.
final class RemoteElementContext {
  const RemoteElementContext({
    required this.remote,
    this.settings = const {},
    this.buildContext,
  });

  final RemotePanel remote;

  /// The placed item's saved settings, such as a label or preset value.
  final Map<String, String> settings;

  /// Where the element is drawn, for actions that open dialogs. Null when an
  /// element is resolved outside the widget tree.
  final BuildContext? buildContext;

  /// The stored device profile (name, endpoints, metadata) when one is selected.
  RemoteDevice? get device => remote.device;
}
