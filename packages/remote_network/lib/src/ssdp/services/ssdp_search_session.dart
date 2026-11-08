import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/ssdp_advertisement.dart';

/// Owns socket, deadline, packet collection, and cleanup for one search.
final class SsdpSearchSession {
  SsdpSearchSession({
    required this.serviceType,
    required this.duration,
    this.localAddress,
    this.onAdvertisement,
    this.destination,
    this.destinationPort = 1900,
  });
  final String serviceType;
  final Duration duration;
  final InternetAddress? localAddress;
  final InternetAddress? destination;
  final int destinationPort;
  final void Function(SsdpAdvertisement)? onAdvertisement;
  bool _sent = false;
  final _completed = Completer<void>();
  final _found = <String, SsdpAdvertisement>{};
  late final RawDatagramSocket _socket;
  Future<List<SsdpAdvertisement>> run({Future<void>? cancelled}) async {
    _socket = await RawDatagramSocket.bind(
      localAddress ?? InternetAddress.anyIPv4,
      0,
    );
    _socket.writeEventsEnabled = false;
    final timer = Timer(duration, _complete);
    final subscription = _socket.listen(_socketEvent, onError: _failed);
    try {
      _configureMulticast();
      _sendSearch();
      await Future.any<void>([
        _completed.future,
        if (cancelled != null) cancelled,
      ]);
      return List.unmodifiable(_found.values);
    } finally {
      timer.cancel();
      await subscription.cancel();
      _socket.close();
    }
  }

  void _complete() {
    if (_completed.isCompleted) {
      return;
    }
    if (!_sent) {
      _failed(
        const SocketException('The discovery request could not be sent.'),
        StackTrace.current,
      );
      return;
    }
    _completed.complete();
  }

  void _failed(Object error, StackTrace stack) {
    if (_completed.isCompleted) {
      return;
    }
    _completed.completeError(error, stack);
  }

  void _socketEvent(RawSocketEvent event) {
    if (event == RawSocketEvent.write) {
      _sendSearch();
      return;
    }
    if (event != RawSocketEvent.read) {
      return;
    }
    Datagram? datagram;
    while ((datagram = _socket.receive()) != null) {
      _accept(datagram!);
    }
  }

  void _accept(Datagram datagram) {
    try {
      final advertisement = SsdpAdvertisement.parse(
        datagram.data,
        datagram.address,
      );
      if (advertisement.serviceType != serviceType) {
        return;
      }
      _remember(advertisement);
    } on FormatException {
      /* Unrelated or malformed LAN traffic is ignored. */
    }
  }

  void _remember(SsdpAdvertisement advertisement) {
    final isNew = !_found.containsKey(advertisement.identity);
    _found[advertisement.identity] = advertisement;
    if (isNew) {
      onAdvertisement?.call(advertisement);
    }
  }

  void _configureMulticast() {
    _socket.multicastHops = 2;
    final address = localAddress;
    if (address == null) {
      return;
    }
    // The multicastInterface property is unimplemented in Dart. The SDK's
    // portable native constants select IP_MULTICAST_IF without OS magic values.
    _socket.setRawOption(
      RawSocketOption(
        RawSocketOption.levelIPv4,
        RawSocketOption.IPv4MulticastInterface,
        address.rawAddress,
      ),
    );
  }

  void _sendSearch() {
    if (_sent) {
      _socket.writeEventsEnabled = false;
      return;
    }
    final request = utf8.encode(
      'M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: "ssdp:discover"\r\nMX: 2\r\nST: $serviceType\r\n\r\n',
    );
    final sent = _socket.send(
      request,
      destination ?? InternetAddress('239.255.255.250'),
      destinationPort,
    );
    _sent = sent == request.length;
    _socket.writeEventsEnabled = !_sent;
  }
}
