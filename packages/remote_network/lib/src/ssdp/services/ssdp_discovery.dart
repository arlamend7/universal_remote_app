import 'dart:io';

import '../models/ssdp_advertisement.dart';
import '../models/ssdp_route_result.dart';
import '../models/ssdp_socket_failure.dart';
import 'ssdp_search_session.dart';

/// Searches each active IPv4 address instead of relying on the default route.
final class SsdpDiscovery {
  const SsdpDiscovery({
    this.duration = const Duration(seconds: 3),
    this.addresses,
    this.searchRoute,
  });
  final Duration duration;
  final Future<List<InternetAddress>> Function()? addresses;
  final Future<List<SsdpAdvertisement>> Function(
    String,
    Duration,
    InternetAddress,
    Future<void>?,
  )?
  searchRoute;
  Future<List<SsdpAdvertisement>> search(
    String serviceType, {
    Future<void>? cancelled,
    void Function(SsdpAdvertisement)? onAdvertisement,
    bool broadFallback = false,
    void Function(String)? onStage,
  }) async {
    if (serviceType.contains(RegExp(r'[\r\n]')) || duration <= Duration.zero) {
      throw ArgumentError('Invalid SSDP search.');
    }
    final routes = await (addresses?.call() ?? _localAddresses());
    if (routes.isEmpty) {
      throw const SsdpSocketFailure('noInterface', 'No active IPv4 interface');
    }
    routes.forEach((_) => onStage?.call('ssdp.interfaceDetected'));
    final results = await Future.wait(
      routes.map(
        (address) => _searchAddress(
          serviceType,
          address,
          cancelled,
          onAdvertisement,
          broadFallback,
          onStage,
        ),
      ),
    );
    return _collect(results);
  }

  Future<List<InternetAddress>> _localAddresses() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    return interfaces.expand((interface) => interface.addresses).toList();
  }

  Future<SsdpRouteResult> _searchAddress(
    String serviceType,
    InternetAddress address,
    Future<void>? cancelled,
    void Function(SsdpAdvertisement)? onAdvertisement,
    bool broadFallback,
    void Function(String)? onStage,
  ) async {
    try {
      final advertisements =
          await (searchRoute?.call(serviceType, duration, address, cancelled) ??
              SsdpSearchSession(
                serviceType: serviceType,
                duration: duration,
                localAddress: address,
                onAdvertisement: onAdvertisement,
                broadFallback: broadFallback,
                onStage: onStage,
              ).run(cancelled: cancelled));
      return SsdpRouteResult(advertisements: advertisements);
    } catch (error) {
      final stage = error is SsdpSocketFailure ? error.stage : 'unknown';
      onStage?.call('ssdp.routeFailed.$stage');
      return SsdpRouteResult(error: error);
    }
  }

  List<SsdpAdvertisement> _collect(List<SsdpRouteResult> results) {
    final successful = results.where((result) => result.succeeded).toList();
    if (successful.isEmpty) {
      throw results.first.error!;
    }
    final devices = <String, SsdpAdvertisement>{};
    for (final result in successful) {
      _merge(result, devices);
    }
    return List.unmodifiable(devices.values);
  }

  void _merge(SsdpRouteResult result, Map<String, SsdpAdvertisement> devices) {
    for (final advertisement in result.advertisements) {
      devices.putIfAbsent(advertisement.identity, () => advertisement);
    }
  }
}
