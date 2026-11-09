import 'package:remote_core/remote_core.dart';

import '../models/ssdp_advertisement.dart';
import 'ssdp_discovery.dart';

final class SsdpProtocol {
  const SsdpProtocol({this.discovery = const SsdpDiscovery()});

  final SsdpDiscovery discovery;

  Future<void> search(
    String service,
    DiscoveryCancellation cancellation,
    Future<void> Function(DiscoveryObservation) observe,
  ) async {
    final seen = <String>{};
    final pending = <Future<void>>[];
    void publish(SsdpAdvertisement reply) {
      if (cancellation.isCancelled ||
          seen.length >= 128 ||
          !seen.add(reply.identity)) {
        return;
      }
      pending.add(observe(_observation(service, reply)));
    }

    try {
      final replies = await discovery.search(
        service,
        cancelled: cancellation.whenCancelled,
        onStage: cancellation.record,
        broadFallback: true,
        onAdvertisement: publish,
      );
      replies.forEach(publish);
    } finally {
      await Future.wait(pending);
    }
  }

  DiscoveryObservation _observation(String service, SsdpAdvertisement reply) =>
      DiscoveryObservation(
        protocolId: DiscoveryProtocol.ssdp,
        serviceType: service,
        endpoint: Uri(scheme: 'udp', host: reply.source.address),
        metadata: {
          for (final key in [
            'usn',
            'st',
            'location',
            'friendlyname',
            'modelname',
          ])
            if (reply.headers[key] case final value?)
              if (value.length <= 1024) key: value,
        },
      );
}
