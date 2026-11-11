import 'dart:convert';

final class SsapRequest {
  SsapRequest({
    required this.id,
    required this.uri,
    Map<String, Object?> payload = const {},
  }) : payload = Map.unmodifiable(payload) {
    if (id.isEmpty || uri.scheme != 'ssap' || uri.host.isEmpty) {
      throw ArgumentError('An ID and ssap URI are required.');
    }
  }
  final String id;
  final Uri uri;
  final Map<String, Object?> payload;
  String encode() => jsonEncode({
    'id': id,
    'type': 'request',
    'uri': uri.toString(),
    'payload': payload,
  });
}
