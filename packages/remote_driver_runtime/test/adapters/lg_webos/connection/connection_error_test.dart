import 'dart:async';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/src/adapters/lg_webos/connection/functions/lg_connection_error.dart';
import 'package:test/test.dart';

void main() {
  test('secure-storage failures stay distinct from network failures', () {
    const error = RemoteException(
      'credentialStorage',
      'Protected storage unavailable',
    );
    expect(lgConnectionError(error), same(error));
  });
  test(
    'certificate and other TLS handshake failures have actionable messages',
    () {
      final certificate = lgConnectionError(
        const HandshakeException('CERTIFICATE_VERIFY_FAILED'),
      );
      final handshake = lgConnectionError(
        const HandshakeException('protocol failure'),
      );
      expect(certificate.code, 'tls');
      expect(certificate.message, contains('certificate was rejected'));
      expect(handshake.message, contains('handshake failed'));
    },
  );
  test(
    'network access, refused port, timeout and upgrade failures are distinct',
    () {
      expect(
        lgConnectionError(
          const SocketException('hidden', osError: OSError('denied', 65)),
        ).code,
        'networkAccess',
      );
      expect(
        lgConnectionError(
          const SocketException('hidden', osError: OSError('refused', 61)),
        ).code,
        'connectionRefused',
      );
      expect(lgConnectionError(TimeoutException('hidden')).code, 'timeout');
      expect(
        lgConnectionError(const WebSocketException('hidden')).code,
        'websocket',
      );
    },
  );
}
