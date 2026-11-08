import 'remote_element_context.dart';
import 'remote_element.dart';

final class RemoteInput<TDevice, TValue> extends RemoteElement<TDevice> {
  const RemoteInput(
    super.id, {
    super.slots,
    super.icon,
    required this.commit,
    this.preview,
    this.current,
    this.maximum = 100,
  });

  /// The device's present value, for inputs shown as a slider or dial.
  final double? Function(RemoteElementContext context)? current;

  /// Upper bound of a numeric input; the lower bound is zero.
  final double maximum;

  final void Function(TDevice device, TValue value)? preview;
  final Future<void> Function(TDevice device, TValue value) commit;
}
