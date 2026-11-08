import 'remote_element.dart';

final class RemoteInput<TDevice, TValue> extends RemoteElement<TDevice> {
  const RemoteInput(
    super.id, {
    super.slots,
    super.icon,
    required this.commit,
    this.preview,
  });

  final void Function(TDevice device, TValue value)? preview;
  final Future<void> Function(TDevice device, TValue value) commit;
}
