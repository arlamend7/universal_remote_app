import 'package:flutter/widgets.dart' show IconData;

import 'remote_element.dart';
import 'remote_element_context.dart';

/// What an action looks like and does right now. Resolving it is cheap and
/// pure; only [execute] runs the command.
typedef ResolvedAction = ({
  IconData? icon,
  String label,
  bool enabled,
  Future<void> Function() execute,
});

/// One discrete command. Its [builder] returns the icon, label, enabled state
/// and execution together, from the device and the current state.
final class RemoteAction<TDevice> extends RemoteElement<TDevice> {
  const RemoteAction(
    super.id, {
    super.slots,
    this.showLabel = true,
    this.holdable = false,
    this.usableOffline = false,
    required this.builder,
  });

  /// Whether the label is drawn (the user may still hide it per item).
  final bool showLabel;

  /// Whether holding the button repeats the command when the item allows it.
  final bool holdable;

  /// Whether the action works while the device is disconnected or busy, such
  /// as waking, reconnecting or opening details.
  final bool usableOffline;

  /// [RemoteElementContext.buildContext] and [RemoteElementContext.settings]
  /// are there for dialogs and item settings.
  final ResolvedAction Function(RemoteElementContext context, TDevice device)
  builder;
}
