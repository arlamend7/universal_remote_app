import 'package:remote_core/remote_core.dart';

/// Visible applications plus every ID the TV reported, including hidden
/// system apps that other operations (such as settings) depend on.
final class SsapApplicationList {
  const SsapApplicationList(this.visible, this.reported);

  final List<DeviceApplication> visible;
  final Set<String> reported;
}
