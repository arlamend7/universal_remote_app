import 'package:remote_core/remote_core.dart';

Uri samsungEndpoint(String host) {
  if (!isLocalProbeAddress(host)) {
    throw const FormatException(
      'Enter the Samsung TV’s numeric local IP address.',
    );
  }
  return Uri(
    scheme: 'wss',
    host: host,
    port: 8002,
    path: '/api/v2/channels/samsung.remote.control',
  );
}
