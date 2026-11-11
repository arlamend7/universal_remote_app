/// Exact catalog envelope and its conditional-request metadata.
final class CachedDriverCatalog {
  const CachedDriverCatalog(this.envelope, {this.etag});

  factory CachedDriverCatalog.fromJson(Map<String, Object?> json) {
    final envelope = json['envelope'];
    final etag = json['etag'];
    if (envelope is! String ||
        envelope.isEmpty ||
        (etag != null && etag is! String)) {
      throw const FormatException('Invalid driver catalog cache.');
    }
    return CachedDriverCatalog(envelope, etag: etag as String?);
  }

  final String envelope;
  final String? etag;

  Map<String, Object?> toJson() => {'envelope': envelope, 'etag': etag};
}
