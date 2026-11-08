import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/ssdp_advertisement.dart';
import '../models/ssdp_socket_failure.dart';

/// Owns socket, deadline, packet collection, and cleanup for one search.
final class SsdpSearchSession {
  SsdpSearchSession({
    required this.serviceType,
    required this.duration,
    this.localAddress,
    this.onAdvertisement,
    this.destination,
    this.destinationPort = 1900,
    this.broadFallback = false,
    this.onStage,
  });
  final String serviceType;
  final Duration duration;
  final InternetAddress? localAddress;
  final InternetAddress? destination;
  final int destinationPort;
  final bool broadFallback;
  final void Function(String)? onStage;
  final void Function(SsdpAdvertisement)? onAdvertisement;
  static const _maxAttempts = 3;
  int _attempts = 0;
  bool _sent = false;
  final _completed = Completer<void>();
  final _found = <String, SsdpAdvertisement>{};
  late final RawDatagramSocket _socket;
  Future<List<SsdpAdvertisement>> run({Future<void>? cancelled}) async {
    var cancellationRequested = false;
    unawaited(cancelled?.then((_) => cancellationRequested = true));
    _socket = await _bind();
    if (cancellationRequested) {
      _socket.close();
      return [];
    }
    _socket.writeEventsEnabled = false;
    final deadline = Timer(duration, _complete);
    final retry = Timer.periodic(
      duration ~/ (_maxAttempts * 2),
      (_) => _sendSearch(),
    );
    final subscription = _socket.listen(
      _socketEvent,
      onError: (Object error, StackTrace stack) =>
          _failed(SsdpSocketFailure('receive', error), stack),
    );
    try {
      _startSearch();
      await Future.any<void>([
        _completed.future,
        if (cancelled != null) cancelled,
      ]);
      return List.unmodifiable(_found.values);
    } finally {
      deadline.cancel();
      retry.cancel();
      _socket.close();
      await subscription.cancel();
    }
  }

  Future<RawDatagramSocket> _bind() async {
    try {
      return await RawDatagramSocket.bind(
        localAddress ?? InternetAddress.anyIPv4,
        0,
      );
    } on SocketException catch (error) {
      throw SsdpSocketFailure('bind', error);
    }
  }

  void _startSearch() {
    try {
      _configureMulticast();
    } catch (error, stack) {
      _failed(SsdpSocketFailure('interface', error), stack);
      return;
    }
    _sendSearch();
  }

  void _complete() {
    if (_completed.isCompleted) {
      return;
    }
    if (!_sent) {
      _failed(
        const SsdpSocketFailure('send', 'No datagram accepted'),
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
    if (event != RawSocketEvent.read) {
      return;
    }
    try {
      _receive();
    } catch (error, stack) {
      _failed(SsdpSocketFailure('receive', error), stack);
    }
  }

  void _receive() {
    Datagram? datagram;
    while ((datagram = _socket.receive()) != null) {
      _accept(datagram!);
    }
  }

  void _accept(Datagram datagram) {
    onStage?.call('ssdp.responseReceived');
    try {
      final advertisement = SsdpAdvertisement.parse(
        datagram.data,
        datagram.address,
      );
      if (!_matchesService(advertisement)) {
        onStage?.call('ssdp.responseRejected.service');
        return;
      }
      _remember(advertisement);
    } on FormatException {
      onStage?.call('ssdp.responseRejected.format');
    }
  }

  bool _matchesService(SsdpAdvertisement advertisement) {
    final target = serviceType.toLowerCase();
    return advertisement.serviceType.toLowerCase() == target ||
        (broadFallback &&
            advertisement.usn.toLowerCase().endsWith('::$target'));
  }

  void _remember(SsdpAdvertisement advertisement) {
    final isNew = !_found.containsKey(advertisement.identity);
    _found[advertisement.identity] = advertisement;
    if (isNew) {
      onStage?.call('ssdp.advertisementMatched');
      onAdvertisement?.call(advertisement);
      return;
    }
    onStage?.call('ssdp.advertisementDuplicate');
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
    if (_completed.isCompleted || _attempts >= _maxAttempts) {
      return;
    }
    _attempts++;
    try {
      _sent = _sendDatagram() || _sent;
    } catch (error, stack) {
      _failed(SsdpSocketFailure('send', error), stack);
    }
  }

  bool _sendDatagram() {
    final target = broadFallback && _attempts == _maxAttempts && _found.isEmpty
        ? 'ssdp:all'
        : serviceType;
    final request = utf8.encode(
      'M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: "ssdp:discover"\r\nMX: 2\r\nST: $target\r\n\r\n',
    );
    final sent = _socket.send(
      request,
      destination ?? InternetAddress('239.255.255.250'),
      destinationPort,
    );
    final accepted = sent == request.length;
    onStage?.call(accepted ? 'ssdp.datagramSent' : 'ssdp.datagramDeferred');
    return accepted;
  }
}
