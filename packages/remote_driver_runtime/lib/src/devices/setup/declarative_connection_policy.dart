import 'dart:convert';

import 'package:remote_core/remote_core.dart';

/// `device.json#policy`: what counts as the same connection, which errors
/// justify waking and retrying, and how certificates are reviewed.
final class DeclarativeConnectionPolicy implements DeviceConnectionPolicy {
  DeclarativeConnectionPolicy(this.category, this.json);

  @override
  final DeviceCategory category;
  final Map<String, Object?> json;

  List<String> get _same =>
      ((json['sameConnection'] as List?) ?? const []).cast<String>();
  Set<String> get _retry =>
      ((json['retryAfterWake'] as List?) ?? const []).cast<String>().toSet();
  Map<String, Object?>? get _review =>
      json['certificateReview'] as Map<String, Object?>?;

  @override
  bool sameConnection(RemoteDevice previous, RemoteDevice next) =>
      _same.every((key) => previous.metadata[key] == next.metadata[key]);

  @override
  bool canRetryAfterWake(Object error) =>
      error is RemoteException && _retry.contains(error.code);

  @override
  bool canReviewCertificate(RemoteDevice device, String? errorCode) {
    final review = _review;
    return review != null &&
        errorCode == review['errorCode'] &&
        device.endpoints.firstOrNull?.scheme == review['scheme'];
  }

  @override
  RemoteDevice trustCertificate(RemoteDevice device, String certificate) {
    final bytes = base64Decode(certificate.trim());
    if (bytes.isEmpty || bytes.length > 16384) {
      throw const FormatException('Enter a valid base64 DER certificate.');
    }
    return copyDevice(
      device,
      metadata: {
        ...device.metadata,
        'trustedCertificateDer': base64Encode(bytes),
      },
    );
  }

  @override
  RemoteDevice mergeDiscovered(RemoteDevice saved, RemoteDevice discovered) {
    if (json['mergeDiscovered'] != 'replace-host') {
      return copyDevice(saved, endpoints: discovered.endpoints);
    }
    final previous = saved.endpoints.firstOrNull;
    final current = discovered.endpoints.firstOrNull;
    return copyDevice(
      discovered,
      name: saved.name,
      metadata: {...discovered.metadata, ...saved.metadata},
      endpoints: previous == null || current == null
          ? discovered.endpoints
          : [previous.replace(host: current.host)],
    );
  }
}
