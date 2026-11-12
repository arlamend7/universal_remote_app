/// Untrusted DNS-SD TXT entries (`key=value`) turned into bounded discovery
/// metadata. Keys are lower-cased and prefixed with `txt.` so they can never
/// shadow metadata the app derives itself (`name`, peer identities, ...).
abstract final class BonjourTextRecord {
  static const prefix = 'txt.';
  static const maximumEntries = 16;
  static const maximumValueLength = 128;
  static final _key = RegExp(r'^[a-z0-9_.-]{1,32}$');
  static final _control = RegExp(r'[\u0000-\u001f\u007f�]');

  static Map<String, String> metadata(Iterable<String> entries) {
    final result = <String, String>{};
    for (final entry in entries) {
      if (result.length == maximumEntries) {
        break;
      }
      final pair = _pair(entry);
      if (pair != null) {
        result.putIfAbsent('$prefix${pair.$1}', () => pair.$2);
      }
    }
    return result;
  }

  /// The multicast_dns representation: one entry per line.
  static Map<String, String> fromLines(String text) =>
      metadata(text.split('\n'));

  static (String, String)? _pair(String entry) {
    final separator = entry.indexOf('=');
    if (separator <= 0) {
      return null;
    }
    final key = entry.substring(0, separator).trim().toLowerCase();
    final value = entry
        .substring(separator + 1)
        .replaceAll(_control, '')
        .trim();
    if (!_key.hasMatch(key) ||
        value.isEmpty ||
        value.length > maximumValueLength) {
      return null;
    }
    return (key, value);
  }
}
