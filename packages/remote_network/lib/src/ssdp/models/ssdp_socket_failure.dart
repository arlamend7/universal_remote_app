import 'dart:io';

/// A safe description of the failed SSDP operation with the original cause.
final class SsdpSocketFailure implements SocketException {
  const SsdpSocketFailure(this.stage, this.cause);

  final String stage;
  final Object cause;

  @override
  String get message => 'SSDP failed during $stage.';
  @override
  OSError? get osError => switch (cause) {
    SocketException(:final osError) => osError,
    OSError error => error,
    _ => null,
  };
  @override
  InternetAddress? get address => null;
  @override
  int? get port => null;
}
