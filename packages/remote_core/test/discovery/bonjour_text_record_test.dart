import 'package:remote_core/remote_core.dart';
import 'package:test/test.dart';

void main() {
  test('TXT entries become prefixed, lower-cased metadata', () {
    expect(BonjourTextRecord.fromLines('bt=AA:BB:CC:DD:EE:FF\nVer=2\n'), {
      'txt.bt': 'AA:BB:CC:DD:EE:FF',
      'txt.ver': '2',
    });
  });

  test('untrusted entries are bounded and sanitized', () {
    final entries = [
      'name=spoofed', // kept, but under txt.name: never shadows 'name'
      'flag', // boolean attribute without a value
      '=value',
      'bad key=1',
      'empty=',
      'long=${'x' * 200}',
      'ctl=a\u0000b',
      'bt=first',
      'bt=second',
      for (var index = 0; index < 30; index++) 'k$index=v',
    ];
    final metadata = BonjourTextRecord.metadata(entries);
    expect(metadata['txt.name'], 'spoofed');
    expect(metadata.containsKey('name'), isFalse);
    expect(metadata['txt.ctl'], 'ab');
    expect(metadata['txt.bt'], 'first');
    for (final key in ['txt.flag', 'txt.', 'txt.bad key', 'txt.empty']) {
      expect(metadata.containsKey(key), isFalse, reason: key);
    }
    expect(metadata.containsKey('txt.long'), isFalse);
    expect(metadata, hasLength(BonjourTextRecord.maximumEntries));
  });
}
