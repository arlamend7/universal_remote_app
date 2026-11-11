import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import 'driver_command.dart';
import 'driver_text_session.dart';

typedef DriverWebSocketConnector = Future<TextTransport> Function(
  Uri endpoint, {
  required Stream<void> cancellation,
  required Duration timeout,
  String? trustedCertificateDer,
});

final class DriverRuntime {
  const DriverRuntime({DriverWebSocketConnector? connect})
    : _connect = connect ?? IoWebSocketTransport.connect;

  final DriverWebSocketConnector _connect;

  Future<Map<String, Object?>?> execute(
    DriverCommand command, {
    required Uri endpoint,
    String? trustedCertificateDer,
    Stream<void>? cancellation,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    _validateEndpoint(endpoint);
    if (timeout <= Duration.zero || timeout > const Duration(seconds: 30)) {
      throw ArgumentError(
        'Driver execution timeout must be within 30 seconds.',
      );
    }
    final stop = StreamController<void>.broadcast();
    final interrupted = Completer<Never>();
    DriverTextSession? session;
    var finished = false;

    void interrupt(String code, String message) {
      if (finished || interrupted.isCompleted) {
        return;
      }
      interrupted.completeError(RemoteException(code, message));
      stop.add(null);
    }

    final timeoutTimer = Timer(
      timeout,
      () => interrupt('driverTimeout', 'Driver command timed out.'),
    );
    final listener = cancellation?.listen(
      (_) => interrupt('cancelled', 'Driver command cancelled.'),
      onError: (Object _) =>
          interrupt('cancelled', 'Driver command cancelled.'),
    );
    try {
      final execution = _run(
        command,
        open: () async {
          final transport = await _connect(
            endpoint,
            timeout: timeout,
            cancellation: stop.stream,
            trustedCertificateDer: trustedCertificateDer,
          );
          if (finished || interrupted.isCompleted) {
            await transport.close();
            throw const RemoteException('cancelled', 'Driver command ended.');
          }
          return session = DriverTextSession(transport);
        },
        active: () => !finished && !interrupted.isCompleted,
      );
      return await Future.any([interrupted.future, execution]);
    } finally {
      finished = true;
      timeoutTimer.cancel();
      await listener?.cancel();
      await stop.close();
      await session?.close();
    }
  }

  Future<Map<String, Object?>?> _run(
    DriverCommand command, {
    required Future<DriverTextSession> Function() open,
    required bool Function() active,
  }) async {
    final session = await open();
    Map<String, Object?>? response;
    for (final step in command.steps.skip(1)) {
      if (!active()) {
        throw const RemoteException('cancelled', 'Driver command ended.');
      }
      switch (step.operation) {
        case DriverOperation.webSocketSendJson:
          await session.send(step.message!);
        case DriverOperation.webSocketAwaitJson:
          response = await session.receiveJson();
        case DriverOperation.webSocketDisconnect:
          return response;
        case DriverOperation.webSocketConnect:
          throw StateError('Unexpected driver connection step.');
      }
    }
    throw StateError('Driver command did not terminate.');
  }

  static void _validateEndpoint(Uri endpoint) {
    if (endpoint.scheme != 'wss' ||
        !isLocalProbeAddress(endpoint.host) ||
        endpoint.userInfo.isNotEmpty ||
        endpoint.hasFragment) {
      throw const RemoteException(
        'driverEndpoint',
        'The driver requires a secure local WebSocket endpoint.',
      );
    }
  }
}
