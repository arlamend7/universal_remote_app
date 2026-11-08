import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:remote_network/src/ssdp/services/ssdp_search_session.dart';
import 'package:test/test.dart';

void main() {
  test(
    'a real UDP responder receives M-SEARCH and replies to its source port',
    () async {
      final server = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
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
        server.send(
          utf8.encode(
            'HTTP/1.1 200 OK\r\nUSN: uuid:fake-tv::service\r\nST: service\r\n\r\n',
          ),
          datagram.address,
          datagram.port,
        );
      });
      try {
        final session = SsdpSearchSession(
          serviceType: 'service',
          duration: const Duration(milliseconds: 100),
          localAddress: InternetAddress.loopbackIPv4,
          destination: InternetAddress.loopbackIPv4,
          destinationPort: server.port,
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
      } finally {
        await listener.cancel();
        server.close();
      }
    },
  );
}
