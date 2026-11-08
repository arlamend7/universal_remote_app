import 'dart:convert';
import 'dart:io';

import 'dependencies/dependency_graph_snapshot.dart';
import 'dependencies/dependency_source_policy.dart';

/// Compare all resolved entries and edges with the reviewed source snapshot.
Future<void> main(List<String> arguments) async {
  final result = await Process.run(
    arguments.isEmpty ? 'flutter' : arguments.single,
    ['pub', 'deps', '--json'],
  );
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exitCode = result.exitCode;
    return;
  }
  final graph = jsonDecode(result.stdout as String) as Map<String, dynamic>;
  final reviewed = jsonDecode(
    File('docs/dependency-graph.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final current = DependencyGraphSnapshot(graph);
  final changes = current.changesFrom(DependencyGraphSnapshot(reviewed));
  if (changes.isNotEmpty) {
    throw StateError('Dependency review required: ${changes.join(', ')}');
  }
  DependencySourcePolicy().verify(
    graph,
    File('pubspec.lock').readAsStringSync(),
  );
  stdout.writeln(
    'PASS: ${current.packages.length} reviewed graph entries; pinned route_definer 4.0.0; no Riverpod.',
  );
}
