import 'dart:async';
import 'dart:io';

import 'package:remote_network/remote_network.dart';

import 'discovery_diagnostic_fields.dart';

/// Safe discovery diagnostics. Raw exception payloads are never displayed.
String discoveryFailureMessage(Object failure) {
  final diagnostic = discoveryFailureCode(failure);
  final osCode = discoveryOsCode(failure);
  switch (diagnostic) {
    case 'localNetworkDenied':
      return 'Local Network access was denied. Enable it for Universal Remote in Settings, then search again.';
    case 'discoveryUnavailable':
      return 'This discovery protocol is unavailable. Try Connect by IP.';
    case 'bonjourUnavailable':
      return 'The iOS Bonjour adapter is unavailable. Install the latest build or connect by IP.';
    case 'bonjourResolveFailed':
      return 'An Android TV advertised its service, but its address could not be resolved. Retry or connect by IP.';
    case 'bonjourBrowseFailed':
    case 'mdnsOperationFailed':
      return 'Android TV discovery could not complete. Check Local Network access and Wi-Fi, then retry or connect by IP.';
    case 'identificationFailed':
      return 'A device responded but could not be identified. Search again or connect by IP.';
    case 'devicePermissionDenied':
      return 'The device denied the request. Check its mobile remote-control setting, then retry.';
    case 'invalidAdvertisement':
      return 'A discovery response could not be read. Retry or connect by IP.';
    case 'networkBlocked':
      return 'Network discovery was blocked by the system (code $osCode). Check Local Network access. On iOS, verify the signed build has multicast access for LG discovery.';
    case 'networkUnreachable':
      return 'No usable route or Local Network access is blocked (code $osCode). Check Wi-Fi and Local Network access. On iOS, verify multicast signing for LG discovery.';
  }
  if (failure is TimeoutException || diagnostic == 'responseTimeout') {
    return 'Discovery timed out. Check the TV is on the same network, then retry.';
  }
  if (failure is! SocketException) {
    return 'Network discovery failed. Check local-network access and retry, or connect by IP.';
  }
  final code = failure.osError?.errorCode;
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
