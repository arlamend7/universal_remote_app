import 'dart:async';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

Future<TextTransport> openSamsungTransport(Uri endpoint, String pin) async {
  try {
    return await IoWebSocketTransport.connect(
      endpoint,
      trustedCertificateDer: pin,
    );
  } on HandshakeException {
    throw const RemoteException(
      'tls',
      'Review the Samsung TV certificate before connecting.',
    );
  } on TimeoutException {
    throw const RemoteException(
      'timeout',
      'The Samsung TV did not respond in time.',
    );
  } on Exception {
    throw const RemoteException(
      'network',
      'Could not open the Samsung TV remote channel.',
    );
  }
}
