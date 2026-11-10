import 'dart:async';

import 'remote_element.dart';
import 'remote_element_context.dart';
import 'remote_reading.dart';

/// Read-only information. It reads observable state and the stored device
/// profile through [RemoteElementContext], and never issues a network request.
final class RemoteInfo<TDevice> extends RemoteElement<TDevice> {
  const RemoteInfo(
    super.id, {
    super.slots,
    super.icon,
    this.defaultLabel,
    this.showLabelByDefault = true,
    this.supportsOfflineIndicator = false,
    this.hiddenWhenOffline = false,
    this.watch,
    required this.read,
  });

  /// Draws nothing while the device is disconnected.
  final bool hiddenWhenOffline;
  final String? defaultLabel;
  final bool showLabelByDefault;
  final bool supportsOfflineIndicator;

  /// Readings pushed by the device between panel updates, when it streams them.
  final Stream<RemoteReading>? Function(RemoteElementContext context)? watch;

  final RemoteReading Function(RemoteElementContext context) read;
}
