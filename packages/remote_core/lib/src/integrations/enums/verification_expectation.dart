/// What a capability verification probe must observe to succeed.
enum VerificationExpectation {
  /// The probe operation completes without an error.
  succeeds('succeeds'),

  /// The probe returns a non-empty list.
  nonEmpty('non-empty'),

  /// The probe reports [CapabilityVerification.value] among a named fact.
  contains('contains');

  const VerificationExpectation(this.id);
  final String id;

  static VerificationExpectation parse(Object? value) {
    final expectation = values.where((candidate) => candidate.id == value);
    if (expectation.isEmpty) {
      throw const FormatException('Unknown verification expectation.');
    }
    return expectation.single;
  }
}
