import 'remote_element.dart';

final class RemoteAction<TDevice, TConfig> extends RemoteElement<TDevice> {
  const RemoteAction(
    super.id, {
    super.slots,
    super.icon,
    required this.onPressed,
  });

  final Future<void> Function(TDevice device, TConfig config) onPressed;
}
