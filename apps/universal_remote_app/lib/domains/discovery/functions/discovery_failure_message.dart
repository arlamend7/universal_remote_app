import 'dart:async';
import 'dart:io';

import 'package:remote_network/remote_network.dart';

/// Safe discovery diagnostics. Raw exception payloads are never displayed.
String discoveryFailureMessage(Object failure) {
  if (failure is TimeoutException) {
    return 'Discovery timed out. Check the TV is on the same network, then retry.';
  }
  if (failure is! SocketException) {
    return 'Network discovery failed. Check local-network access and retry, or connect by IP.';
  }
  final code = failure.osError?.errorCode;
  if (code == 1 || code == 13) {
    return 'Network discovery was blocked by the system (code $code). Check Local Network permission and restart the app after rebuilding.';
  }
  if ({51, 65, 101, 113}.contains(code)) {
    return 'Local-network access was blocked or no usable route exists (code $code). Check Local Network permission, Wi-Fi/Ethernet and VPN settings, then fully restart the app.';
  }
  if (failure is SsdpSocketFailure && failure.stage == 'send') {
    return 'Could not send a discovery request. Check Wi-Fi and Local Network access, or connect by IP.';
  }
  if (failure is SsdpSocketFailure && failure.stage == 'noInterface') {
    return 'No usable discovery interface. Connect to Wi-Fi or Ethernet and retry.';
  }
  if (code == null) {
    return 'Could not open or use the discovery socket. Check Wi-Fi or connect by IP.';
  }
  return 'Local-network discovery failed (socket code $code). Check the network connection or connect by IP.';
}
