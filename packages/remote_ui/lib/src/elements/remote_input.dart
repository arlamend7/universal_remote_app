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
    this.minimum = 0,
    this.maximum = 100,
    this.step,
    this.range,
  });

  /// The device's present value, for inputs shown as a slider or dial.
  final double? Function(RemoteElementContext context)? current;

  final double minimum;
  final double maximum;
  final double? step;
  final ({double minimum, double maximum, double? step}) Function(
    RemoteElementContext context,
  )?
  range;

  ({double minimum, double maximum, double? step}) bounds(
    RemoteElementContext context,
  ) => range?.call(context) ?? (minimum: minimum, maximum: maximum, step: step);

  void Function(TValue)? previewFor(Object? device) {
    final callback = preview;
    return device is TDevice && callback != null
        ? (value) => callback(device, value)
        : null;
  }

  Future<void> Function(TValue)? commitFor(Object? device) =>
      device is TDevice ? (value) => commit(device, value) : null;

  final void Function(TDevice device, TValue value)? preview;
  final Future<void> Function(TDevice device, TValue value) commit;
}
