import 'remote_element.dart';
import 'remote_element_context.dart';
import 'remote_reading.dart';

/// Read-only information. It reads observable state and the stored device
/// profile through [RemoteElementContext], and never issues a network request.
final class RemoteInfo<TDevice> extends RemoteElement<TDevice> {
  const RemoteInfo(super.id, {super.slots, super.icon, required this.read});

  final RemoteReading Function(RemoteElementContext context) read;
}
