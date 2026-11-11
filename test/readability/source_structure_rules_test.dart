import 'package:test/test.dart';

import '../../tool/readability/source_structure_rules.dart';

void main() {
  final rules = SourceStructureRules();
  const source = 'apps/universal_remote_app/lib/example.dart';
  test('rejects multiple types but ignores comments and string contents', () {
    expect(rules.inspect(source, 'class One {} class Two {}'), hasLength(1));
    expect(
      rules.inspect(
        source,
        "// class Fake {}\nclass Actual { final text = 'class Fake {}'; }",
      ),
      isEmpty,
    );
  });
  test('allows two control levels and reports deeper logic', () {
    expect(
      rules.inspect(
        source,
        'void execute() { if (a) { for (final item in items) { work(); } } }',
      ),
      isEmpty,
    );
    expect(
      rules.inspect(
        source,
        'void execute() { if (a) { for (final item in items) { if (b) { work(); } } } }',
      ),
      isNotEmpty,
    );
  });
  test('requires guard clauses and protects pure Dart package boundaries', () {
    expect(
      rules.inspect(
        source,
        'void execute() { if (a) { work(); } else { stop(); } }',
      ),
      isNotEmpty,
    );
    expect(
      rules.inspect(
        'packages/remote_core/lib/example.dart',
        "import 'package:flutter/material.dart';",
      ),
      isNotEmpty,
    );
  });
  test('domain services cannot import data adapters or presentation', () {
    expect(
      rules.inspect(
        'apps/universal_remote_app/lib/domains/example.dart',
        "import 'package:universal_remote_app/data/example.dart';",
      ),
      isNotEmpty,
    );
  });
  test('Flutter imports are confined to the remote UI widget layer', () {
    const flutter = "import 'package:flutter/material.dart';";
    expect(
      rules.inspect('packages/remote_ui/lib/src/widgets/item.dart', flutter),
      isEmpty,
    );
    expect(
      rules.inspect(
        'packages/remote_ui/lib/src/definitions/item.dart',
        flutter,
      ),
      isNotEmpty,
    );
    expect(
      rules.inspect(
        'packages/remote_driver_runtime/lib/src/adapters/lg_webos/example.dart',
        "import 'package:remote_ui/remote_ui.dart';",
      ),
      isNotEmpty,
    );
  });
}
