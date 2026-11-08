import 'ssdp_advertisement.dart';

/// A failing interface must not discard discovery results from a working one.
final class SsdpRouteResult {
  const SsdpRouteResult({this.advertisements = const [], this.error});
  final List<SsdpAdvertisement> advertisements;
  final Object? error;
  bool get succeeded => error == null;
}
