/// Exact catalog envelope and its conditional-request metadata.
final class CachedDriverCatalog {
  const CachedDriverCatalog(this.envelope, {this.etag, this.checkedAt});

  factory CachedDriverCatalog.fromJson(Map<String, Object?> json) {
    final envelope = json['envelope'];
    final etag = json['etag'];
    final checkedAt = json['checkedAt'];
    if (envelope is! String ||
        envelope.isEmpty ||
        (etag != null && etag is! String)) {
      throw const FormatException('Invalid driver catalog cache.');
    }
    return CachedDriverCatalog(
      envelope,
      etag: etag as String?,
      checkedAt: checkedAt is String ? DateTime.tryParse(checkedAt) : null,
    );
  }

  final String envelope;
  final String? etag;
  final DateTime? checkedAt;

  Map<String, Object?> toJson() => {
    'envelope': envelope,
    'etag': etag,
    if (checkedAt != null) 'checkedAt': checkedAt!.toUtc().toIso8601String(),
  };
}
