/// The result of one verification probe run after connecting.
final class VerificationOutcome {
  const VerificationOutcome.success(this.value) : reason = null, ok = true;
  const VerificationOutcome.failure(this.reason) : value = null, ok = false;

  final bool ok;
  final Object? value;

  /// Presentation-safe failure message.
  final String? reason;
}
