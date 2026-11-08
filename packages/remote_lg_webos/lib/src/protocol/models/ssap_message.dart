import 'dart:convert';

/// Validated incoming envelope; no authentication payload is logged or exposed.
final class SsapMessage {
  const SsapMessage({
    required this.id,
    required this.type,
    required this.payload,
    this.error,
  });
  final String? id;
  final String type;
  final Map<String, Object?> payload;
  final Object? error;
  bool get isFailure => type == 'error' || payload['returnValue'] == false;
  factory SsapMessage.parse(String frame) {
    if (frame.length > 2 * 1024 * 1024) {
      throw const FormatException('Oversized SSAP message.');
    }
    final value = jsonDecode(frame);
    if (value is! Map<String, dynamic> || value['type'] is! String) {
      throw const FormatException('Invalid SSAP envelope.');
    }
    final raw = value['payload'];
    return SsapMessage(
      id: value['id'] is String ? value['id'] as String : null,
      type: value['type'] as String,
      payload: raw is Map<String, dynamic> ? raw.cast<String, Object?>() : {},
      error: value['error'],
    );
  }
}
