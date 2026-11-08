import 'package:flutter/widgets.dart' show Widget;

import '../widgets/grid/models/remote_preview_data.dart';
import 'remote_element.dart';

final class RemoteCollection<TDevice, TEntry> extends RemoteElement<TDevice> {
  const RemoteCollection(
    super.id, {
    super.slots,
    super.icon,
    required this.title,
    required this.load,
    required this.entryId,
    required this.entryName,
    required this.fromOption,
    required this.sample,
    required this.onSelected,
    this.leading,
    this.trackedByDevice = false,
  });

  /// Heading of the picker and default label of its launcher button.
  final String title;
  final Future<List<TEntry>> Function(TDevice device) load;
  final String Function(TEntry entry) entryId;
  final String Function(TEntry entry) entryName;

  /// Rebuilds an entry from a stored (id, name) option such as a pinned shortcut.
  final TEntry Function(String id, String name) fromOption;
  final Future<void> Function(TDevice device, TEntry entry) onSelected;

  /// Example entries shown in previews, which never touch a device.
  final List<(String, String)> Function(RemotePreviewData data) sample;

  /// Optional visual drawn instead of the element icon, e.g. an app logo.
  final Widget Function(String id, String name)? leading;

  /// Whether the device reports which entries are installed, so a pinned entry
  /// the device no longer has is shown as unavailable.
  final bool trackedByDevice;

  Future<void> select(TDevice device, String id, String name) =>
      onSelected(device, fromOption(id, name));

  Future<List<(String, String)>> options(TDevice device) async => [
    for (final entry in await load(device)) (entryId(entry), entryName(entry)),
  ];
}
