import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Compares a transcript with `test/parity/golden/<name>.json`.
///
/// Set `UPDATE_PARITY_GOLDENS=1` only when recording the legacy baseline.
///
/// [improvements] documents intended differences for the migrated runtime:
/// each function rewrites the recorded legacy step before comparison.
void expectParityGolden(
  String name,
  List<Map<String, Object?>> transcript, {
  Map<String, Object? Function(Object? legacy)> improvements = const {},
}) {
  final file = _golden(name);
  final actual = '${const JsonEncoder.withIndent('  ').convert(transcript)}\n';
  if (Platform.environment['UPDATE_PARITY_GOLDENS'] == '1') {
    file.writeAsStringSync(actual);
    return;
  }
  expect(
    file.existsSync(),
    isTrue,
    reason: 'Record the legacy parity baseline for $name first.',
  );
  final expected = [
    for (final step in jsonDecode(file.readAsStringSync()) as List<Object?>)
      improvements[(step! as Map)['step']]?.call(step) ?? step,
  ];
  final recorded = jsonDecode(actual) as List<Object?>;
  for (var index = 0; index < expected.length; index++) {
    expect(
      index < recorded.length ? recorded[index] : null,
      expected[index],
      reason: 'Parity step ${(expected[index] as Map)['step']} differs.',
    );
  }
  expect(recorded.length, expected.length);
}

/// Resolves the golden from the package or the repository root.
File _golden(String name) {
  const local = 'test/parity/golden';
  const fromRoot = 'packages/remote_driver_runtime/$local';
  final directory = Directory(local).existsSync() ? local : fromRoot;
  return File('$directory/$name.json');
}
