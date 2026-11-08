import 'dart:convert';
import 'dart:io';

/// One validated SSDP response. Header names are normalized to lower case.
final class SsdpAdvertisement {
  SsdpAdvertisement(this.source, Map<String, String> headers)
    : headers = Map.unmodifiable(headers);
  final InternetAddress source;
  final Map<String, String> headers;
  String get usn => headers['usn']!;
  String get serviceType => headers['st']!;
  String get identity => usn.split('::').first;
  Uri? get location => Uri.tryParse(headers['location'] ?? '');
  static SsdpAdvertisement parse(List<int> bytes, InternetAddress source) {
    if (bytes.length > 65507) {
      throw const FormatException('SSDP datagram too large.');
    }
    final lines = utf8.decode(bytes).split(RegExp(r'\r?\n'));
    if (lines.isEmpty ||
        !RegExp(r'^HTTP/1\.[01] 200(?: |$)').hasMatch(lines.first)) {
      throw const FormatException('Not an SSDP success response.');
    }
    final headers = <String, String>{};
    for (final line in lines.skip(1)) {
      if (line.isEmpty) {
        break;
      }
      final colon = line.indexOf(':');
      if (colon <= 0) {
        throw const FormatException('Malformed SSDP header.');
      }
      final name = line.substring(0, colon).trim().toLowerCase();
      final value = line.substring(colon + 1).trim();
      if (headers.containsKey(name) && headers[name] != value) {
        throw const FormatException('Conflicting SSDP headers.');
      }
      headers[name] = value;
    }
    if (!(headers['usn']?.startsWith('uuid:') ?? false) ||
        headers['usn']!.split('::').first.length <= 5 ||
        (headers['st']?.isEmpty ?? true)) {
      throw const FormatException('Missing SSDP service identity.');
    }
    return SsdpAdvertisement(source, headers);
  }
}
