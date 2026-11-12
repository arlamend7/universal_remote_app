import 'dart:async';
import 'dart:io';

import 'package:remote_core/remote_core.dart';

/// Maps transport failures to presentation-safe, typed connection errors.
RemoteException transportConnectionError(Object error) {
  if (error is RemoteException) {
    return error;
  }
  if (error is TlsException) {
    return _tlsError(error);
  }
  if (error is TimeoutException) {
    return const RemoteException(
      'timeout',
      'The TV did not respond in time. Check that it is on and the control port is reachable.',
    );
  }
  if (error is SocketException) {
    return _socketError(error);
  }
  if (error is WebSocketException) {
    return const RemoteException(
      'websocket',
      'The TV did not accept a remote-control WebSocket connection. Check the selected secure or legacy connection mode.',
    );
  }
  return const RemoteException(
    'network',
    'Could not connect to the TV. Check its network address and local-network permissions.',
  );
}

RemoteException _tlsError(TlsException error) {
  if ('$error'.toLowerCase().contains('certificate')) {
    return const RemoteException(
      'tls',
      'The TV certificate was rejected. Review the TV certificate and approve it only after confirming this is your TV, or configure a verified certificate in Connection details.',
    );
  }
  return const RemoteException(
    'tls',
    'The secure TV handshake failed. Check certificate/TLS compatibility in Connection details. Legacy connection is available only with explicit permission.',
  );
}

RemoteException _socketError(SocketException error) {
  final code = error.osError?.errorCode;
  if ({1, 13, 65}.contains(code)) {
    return RemoteException(
      'networkAccess',
      'Local-network access to the TV was blocked or unreachable (code $code). Confirm the app is allowed in Local Network settings, then fully quit and reopen it.',
    );
  }
  if ({61, 111, 10061}.contains(code)) {
    return const RemoteException(
      'connectionRefused',
      'The TV refused the remote-control connection. Check that the TV is on and supports the selected secure or legacy port.',
    );
  }
  return RemoteException(
    'network',
    'Could not reach the TV${code == null ? '' : ' (socket code $code)'}. Check its address and network connection.',
  );
}
