/// A discovery failure with an operation and safe details for diagnostics.
final class DiscoveryOperationFailure implements Exception {
  const DiscoveryOperationFailure(
    this.stage,
    this.cause, {
    this.code,
    this.osCode,
    this.errorDomain,
  });

  final String stage;
  final Object cause;
  final String? code;
  final int? osCode;
  final String? errorDomain;
}
