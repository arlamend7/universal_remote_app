import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Compares a transcript with `test/parity/golden/<name>.json`.
///
/// Set `UPDATE_PARITY_GOLDENS=1` only when recording the legacy baseline.
void expectParityGolden(String name, List<Map<String, Object?>> transcript) {
  final file = File('test/parity/golden/$name.json');
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
  final expected = jsonDecode(file.readAsStringSync()) as List<Object?>;
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
