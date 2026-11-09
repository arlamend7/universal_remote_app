import 'dart:io';

import 'package:remote_core/remote_core.dart';

import 'ssdp_search_session.dart';

Future<bool> probeSsdpAddress(
  String address,
  String service,
  DiscoveryCancellation cancellation,
) async {
  final destination = InternetAddress.tryParse(address);
  if (destination == null ||
      destination.type != InternetAddressType.IPv4 ||
      cancellation.isCancelled) {
    return false;
  }
  final replies = await SsdpSearchSession(
    serviceType: service,
    destination: destination,
    duration: const Duration(milliseconds: 1500),
  ).run(cancelled: cancellation.whenCancelled);
  return !cancellation.isCancelled &&
      replies.any((reply) => reply.source == destination);
}
