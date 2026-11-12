import '../functions/integration_json.dart';

/// Permanent identity of an integration. Content updates never change it.
final class IntegrationIdentity {
  IntegrationIdentity({required this.integrationId, required this.providerId}) {
    if (!IntegrationJson.isIdentifier(integrationId) ||
        !IntegrationJson.isIdentifier(providerId)) {
      throw const FormatException('Invalid integration identity.');
    }
  }

  final String integrationId;

  /// The stable provider family, such as the saved-device `providerId`.
  final String providerId;

  @override
  bool operator ==(Object other) =>
      other is IntegrationIdentity &&
      other.integrationId == integrationId &&
      other.providerId == providerId;

  @override
  int get hashCode => Object.hash(integrationId, providerId);

  @override
  String toString() => '$providerId/$integrationId';
}
