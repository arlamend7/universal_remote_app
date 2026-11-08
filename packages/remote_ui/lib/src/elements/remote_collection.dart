import 'remote_element.dart';

final class RemoteCollection<TDevice, TEntry> extends RemoteElement<TDevice> {
  const RemoteCollection(
    super.id, {
    super.slots,
    super.icon,
    required this.load,
    required this.entryId,
    required this.entryName,
    required this.onSelected,
  });

  final Future<List<TEntry>> Function(TDevice device) load;
  final String Function(TEntry entry) entryId;
  final String Function(TEntry entry) entryName;
  final Future<void> Function(TDevice device, TEntry entry) onSelected;

  Future<List<(String, String)>> options(TDevice device) async => [
    for (final entry in await load(device)) (entryId(entry), entryName(entry)),
  ];
}
