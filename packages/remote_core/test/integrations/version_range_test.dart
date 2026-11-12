import 'package:remote_core/remote_core.dart';
import 'package:test/test.dart';

void main() {
  group('device version ranges', () {
    test('compare dotted numeric components, not strings', () {
      final range = VersionRange.parse('>=7 <10', VersionScheme.dottedNumeric);
      const scheme = VersionScheme.dottedNumeric;
      expect(range.match('7.0', scheme), VersionMatch.matches);
      expect(range.match('9.10.2', scheme), VersionMatch.matches);
      expect(range.match('10', scheme), VersionMatch.mismatches);
      expect(range.match('6.9', scheme), VersionMatch.mismatches);
    });

    test('unknown or non-numeric software never counts as compatible', () {
      final range = VersionRange.parse('>=7', VersionScheme.dottedNumeric);
      const scheme = VersionScheme.dottedNumeric;
      expect(range.match(null, scheme), VersionMatch.unknown);
      expect(range.match('', scheme), VersionMatch.unknown);
      expect(range.match('webOSTV', scheme), VersionMatch.unknown);
    });

    test('exact ranges match the reported string only', () {
      final range = VersionRange.parse('=T-KTM2', VersionScheme.exact);
      expect(range.match('T-KTM2', VersionScheme.exact), VersionMatch.matches);
      expect(
        range.match('T-KTM2A', VersionScheme.exact),
        VersionMatch.mismatches,
      );
    });

    test('malformed comparisons are rejected', () {
      for (final expression in ['>=x', '~7', '>=7 <8 <9 <10 <11', '']) {
        expect(
          () => VersionRange.parse(expression, VersionScheme.dottedNumeric),
          throwsFormatException,
        );
      }
      expect(compareDottedVersions('04.50', '4.50'), 0);
    });
  });

  test('compatibility combines OS, firmware and model evidence', () {
    final compatibility = IntegrationCompatibility.fromJson({
      'osVersion': '>=7',
      'models': ['OLED55C2'],
    });
    expect(
      compatibility.match(os: '7.1', model: 'OLED55C2'),
      VersionMatch.matches,
    );
    expect(
      compatibility.match(os: '6.0', model: 'OLED55C2'),
      VersionMatch.mismatches,
    );
    expect(compatibility.match(model: 'OLED55C2'), VersionMatch.unknown);
  });
}
