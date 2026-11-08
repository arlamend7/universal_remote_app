import 'dart:convert';

final class DependencyGraphSnapshot {
  DependencyGraphSnapshot(Map<String, dynamic> graph)
    : packages = _normalize(graph);
  final Map<String, String> packages;
  static Map<String, String> _normalize(Map<String, dynamic> graph) => {
    for (final package
        in (graph['packages'] as List<dynamic>).cast<Map<String, dynamic>>())
      package['name'] as String: _signature(package),
  };
  static String _signature(Map<String, dynamic> package) => jsonEncode({
    'version': package['version'],
    'source': package['source'],
    'dependencies': _names(package['dependencies']),
    'devDependencies': _names(package['devDependencies']),
  });
  static List<String> _names(Object? value) =>
      (value as List<dynamic>? ?? []).cast<String>().toList()..sort();
  List<String> changesFrom(DependencyGraphSnapshot reviewed) => {
    ...packages.keys,
    ...reviewed.packages.keys,
  }.where((name) => packages[name] != reviewed.packages[name]).toList()..sort();
}
