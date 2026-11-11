import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';
import 'package:remote_network/remote_network.dart';
import 'package:test/test.dart';

final manifest = DriverManifest(
  identity: DriverIdentity(
    id: 'example.tv',
    providerId: 'example.tv',
    version: DriverVersion.parse('1.0.0'),
  ),
  name: 'Example TV',
  manufacturer: 'Example',
  platform: 'ExampleOS',
  runtime: DriverRuntimeRequirements.parse('>=1.0.0', DriverOperation.values),
  capabilities: [RemoteCapability.volume],
  compatibility: [DriverCompatibility(id: 'generic', version: 1, models: [])],
);

const source = '''
[
  {"operation":"websocket.connect"},
  {"operation":"websocket.sendJson","payload":{"command":"volumeUp"}},
  {"operation":"websocket.awaitJson"},
  {"operation":"websocket.disconnect"}
]
''';

void main() {
  test(
    'a declarative command reaches a fictional TV and reads its reply',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final received = Completer<Object?>();
      final closed = Completer<void>();
      final requests = server.listen((request) async {
        // The client closes the socket at the end of the command.
        // ignore: close_sinks
        final socket = await WebSocketTransformer.upgrade(request);
        socket.listen((message) {
          received.complete(jsonDecode(message as String));
          socket.add('{"volume":21}');
        }, onDone: closed.complete);
      });
      addTearDown(requests.cancel);
      final runtime = DriverRuntime(
        connect:
            (
              _, {
              required cancellation,
              required timeout,
              trustedCertificateDer,
            }) => IoWebSocketTransport.connect(
              Uri(scheme: 'ws', host: '127.0.0.1', port: server.port),
              cancellation: cancellation,
              timeout: timeout,
            ),
      );
      const example = 'drivers/providers/example-tv';
      final source = Directory(example);
      final bundle = await const LocalDriverSource(enabled: true)
          .load(source.existsSync() ? source : Directory('../../$example'));
      final response = await runtime.execute(
        bundle.commands['volume-up']!,
        endpoint: bundle.discovery.endpoint('192.168.1.2'),
      );
      expect(await received.future, {'command': 'volumeUp'});
      expect(response, {'volume': 21});
      await closed.future.timeout(const Duration(seconds: 2));
    },
  );

  test(
    'invalid steps and internet endpoints are rejected before execution',
    () async {
      for (final invalid in [
        source.replaceFirst('websocket.awaitJson', 'shell.exec'),
        source.replaceFirst('websocket.awaitJson', 'websocket.connect'),
        source.replaceFirst(
          '"command":"volumeUp"',
          '"command":"volumeUp"},"uri":"x"',
        ),
      ]) {
        expect(
          () => DriverCommand.parse(invalid, manifest),
          throwsFormatException,
        );
      }
      final command = DriverCommand.parse(source, manifest);
      for (final endpoint in ['wss://example.com', 'ws://192.168.1.2']) {
        await expectLater(
          const DriverRuntime().execute(command, endpoint: Uri.parse(endpoint)),
          throwsA(
            isA<RemoteException>().having(
              (error) => error.code,
              'code',
              'driverEndpoint',
            ),
          ),
        );
      }
    },
  );
}
