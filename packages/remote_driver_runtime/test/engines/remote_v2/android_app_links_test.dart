import 'package:remote_driver_runtime/remote_v2.dart';
import 'package:test/test.dart';

void main() {
  test('a package id launches through a market link', () {
    expect(
      androidAppLink('com.google.android.youtube.tv'),
      'market://launch?id=com.google.android.youtube.tv',
    );
    expect(androidAppLink('vnd.youtube://'), 'vnd.youtube://');
    expect(
      androidAppLink('https://www.netflix.com/title/1'),
      'https://www.netflix.com/title/1',
    );
  });

  test('unsafe or malformed app targets are refused', () {
    for (final target in [
      '',
      'notapackage',
      'com.example;rm',
      'http://example.com',
      'https://user:pw@example.com',
      'javascript:alert(1)',
      'x' * 600,
    ]) {
      expect(androidAppLink(target), isNull, reason: target);
    }
  });
}
