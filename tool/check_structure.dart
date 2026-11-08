import 'dart:io';

import 'readability/source_structure_rules.dart';

void main() {
  final roots = [
    'apps/universal_remote_app/lib',
    'apps/universal_remote_app/test',
    'packages',
    'tool',
  ];
  final issues = roots.expand(_dartFiles).expand(_inspect).toList();
  if (issues.isEmpty) {
    stdout.writeln(
      'PASS: one type per file, shallow control flow, guard clauses and dependency boundaries.',
    );
    return;
  }
  stderr.writeln(issues.join('\n'));
  exitCode = 1;
}

Iterable<File> _dartFiles(String root) =>
    Directory(root)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
Iterable<String> _inspect(File file) =>
    SourceStructureRules().inspect(file.path, file.readAsStringSync());
