import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:remote_network/remote_network.dart';
import 'package:remote_network/src/ssdp/services/ssdp_search_session.dart';
import 'package:test/test.dart';

void main() {
  test('cancelling a search closes the socket before it returns', () async {
    final loopback = InternetAddress.loopbackIPv4;
    final server = await RawDatagramSocket.bind(loopback, 0);
    final request = Completer<int>();
    final listener = server.listen((event) {
      if (event == RawSocketEvent.read && !request.isCompleted) {
        final datagram = server.receive();
        if (datagram != null) {
          request.complete(datagram.port);
        }
      }
    });
    final cancelled = Completer<void>();
    final session = SsdpSearchSession(
      serviceType: 'service',
      duration: const Duration(seconds: 2),
      localAddress: loopback,
      destination: loopback,
      destinationPort: server.port,
    );
    final result = session.run(cancelled: cancelled.future);
    try {
      final port = await request.future.timeout(const Duration(seconds: 1));
      cancelled.complete();
      expect(await result, isEmpty);
      final rebound = await RawDatagramSocket.bind(
        loopback,
        port,
        reuseAddress: false,
      );
      rebound.close();
    } finally {
      if (!cancelled.isCompleted) {
        cancelled.complete();
      }
      await result;
      await listener.cancel();
      server.close();
    }
  });

  test(
    'asynchronous sendto failure retains the send stage and errno',
    () async {
      final session = SsdpSearchSession(
        serviceType: 'service',
        duration: const Duration(milliseconds: 300),
        destination: InternetAddress('255.255.255.255'),
      );
      await expectLater(
        session.run(),
        throwsA(
          isA<SsdpSocketFailure>()
              .having((error) => error.stage, 'operation', 'send')
              .having((error) => error.osError?.errorCode, 'errno', isNotNull),
        ),
      );
    },
  );

  test(
    'SSDP retries, filters a broad search and replies to the source port',
    () async {
      final server = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final stages = <String>[];
      final request = Completer<String>();
      final found = Completer<String>();
      final listener = server.listen((event) {
        if (event != RawSocketEvent.read) {
          return;
        }
        final datagram = server.receive();
        if (datagram == null) {
          return;
        }
        if (!request.isCompleted) {
          request.complete(utf8.decode(datagram.data));
        }
        if (!utf8.decode(datagram.data).contains('ST: ssdp:all')) {
          return;
        }
        server.send(
          utf8.encode(
            'HTTP/1.1 200 OK\r\nUSN: uuid:unrelated\r\nST: upnp:rootdevice\r\n\r\n',
          ),
          datagram.address,
          datagram.port,
        );
        server.send(
          utf8.encode(
            'HTTP/1.1 200 OK\r\nUSN: uuid:fake-tv::service\r\nST: upnp:rootdevice\r\n\r\n',
          ),
          datagram.address,
          datagram.port,
        );
      });
      try {
        final session = SsdpSearchSession(
          serviceType: 'service',
          duration: const Duration(milliseconds: 300),
          localAddress: InternetAddress.loopbackIPv4,
          destination: InternetAddress.loopbackIPv4,
          destinationPort: server.port,
          broadFallback: true,
          onStage: stages.add,
          onAdvertisement: (item) => found.complete(item.identity),
        );
        var completed = false;
        final pending = session.run().then((result) {
          completed = true;
          return result;
        });
        expect(await found.future, 'uuid:fake-tv');
        expect(completed, isFalse);
        final responses = await pending;
        expect(
          await request.future.timeout(const Duration(seconds: 2)),
          contains('M-SEARCH * HTTP/1.1\r\n'),
        );
        expect(responses.single.identity, 'uuid:fake-tv');
        expect(
          stages.where((stage) => stage == 'ssdp.datagramSent'),
          hasLength(3),
        );
        expect(stages, contains('ssdp.responseRejected.service'));
      } finally {
        await listener.cancel();
        server.close();
      }
    },
  );
}
