import '../../device.dart';
import '../enums/verification_expectation.dart';
import '../functions/integration_json.dart';

/// A probe the runtime runs after connecting to confirm a capability.
final class CapabilityVerification {
  CapabilityVerification({
    required this.operation,
    this.expectation = VerificationExpectation.succeeds,
    this.fact,
    this.value,
    this.timeout,
    this.availability = CapabilityAvailability.verified,
  }) {
    final needsFact = expectation == VerificationExpectation.contains;
    if (!IntegrationJson.isIdentifier(operation) ||
        needsFact != (fact != null && value != null) ||
        !{
          CapabilityAvailability.known,
          CapabilityAvailability.verified,
        }.contains(availability)) {
      throw const FormatException('Invalid capability verification.');
    }
  }

  factory CapabilityVerification.fromJson(Object? value) {
    final json = IntegrationJson.object(value, 'verify');
    IntegrationJson.keys(
      json,
      const {
        'operation',
        'expect',
        'fact',
        'value',
        'timeoutMs',
        'availability',
      },
      required: const {'operation'},
    );
    final timeout = json['timeoutMs'];
    return CapabilityVerification(
      operation: IntegrationJson.identifier(json, 'operation'),
      expectation: json.containsKey('expect')
          ? VerificationExpectation.parse(json['expect'])
          : VerificationExpectation.succeeds,
      fact: IntegrationJson.optionalLabel(json, 'fact'),
      value: IntegrationJson.optionalLabel(json, 'value'),
      timeout: timeout == null
          ? null
          : Duration(
              milliseconds: IntegrationJson.integer(
                json,
                'timeoutMs',
                minimum: 100,
                maximum: 30000,
              ),
            ),
      availability: json['availability'] == 'known'
          ? CapabilityAvailability.known
          : CapabilityAvailability.verified,
    );
  }

  final String operation;
  final VerificationExpectation expectation;
  final String? fact, value;
  final Duration? timeout;

  /// Evidence recorded when the probe succeeds.
  final CapabilityAvailability availability;
}
