final class DependencySourcePolicy {
  static const routeRevision = '7546848c78ab81a208655ad7083f608942309b63';
  static const routeRepository =
      'https://github.com/arlamend7/flutter_route_definer.git';
  void verify(Map<String, dynamic> graph, String lock) {
    final packages = (graph['packages'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    if (packages.any(
      (package) => (package['name'] as String).contains('riverpod'),
    )) {
      throw StateError(
        'Riverpod is not allowed by the current user instruction.',
      );
    }
    _verifyServers(lock);
    _verifyRouteRevision(lock);
  }

  void _verifyServers(String lock) {
    for (final match in RegExp(r'url: "([^"]+)"').allMatches(lock)) {
      _verifyServer(match[1]!);
    }
  }

  void _verifyServer(String server) {
    if (server == 'https://pub.dev' || server == routeRepository) {
      return;
    }
    throw StateError('Unreviewed server: $server');
  }

  void _verifyRouteRevision(String lock) {
    final block = RegExp(
      r'^  route_definer:\n([\s\S]*?)(?=^  [a-z_]+:|\Z)',
      multiLine: true,
    ).firstMatch(lock)?[1];
    final revision = block == null
        ? null
        : RegExp(r'resolved-ref:\s*"?([a-f0-9]+)').firstMatch(block)?[1];
    if (revision == routeRevision) {
      return;
    }
    throw StateError(
      'route_definer must use its reviewed web-free Git revision.',
    );
  }
}
