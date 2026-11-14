import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/devices.dart';
import 'package:remote_driver_runtime/protocol_engines.dart';

import 'provider_rule_source.dart';

/// Builds provider definitions from integration data instead of
/// hand-registered manufacturer providers.
///
/// Integrations sharing a provider ID form one family; the highest-priority
/// integration with discovery rules supplies discovery, manual setup,
/// connection policy and wake. The controller factory is generic.
final class IntegrationProviderSource {
  IntegrationProviderSource({
    required this.engines,
    required this.network,
    required this.createController,
    required this.credentials,
    this.allowDevelopment = false,
  });

  final ProtocolEngineRegistry engines;
  final DiscoveryNetwork network;
  final RemoteBase Function(RemoteDevice device) createController;
  final CredentialStore credentials;
  final bool allowDevelopment;

  /// One definition per provider family, skipping invalid rule sets.
  List<ProviderDefinition<RemoteBase>> definitions(
    Iterable<ProviderRuleSource> sources,
  ) {
    final families = <String, ProviderRuleSource>{};
    for (final source in sources.where(_eligible)) {
      final id = source.identity.providerId;
      final current = families[id];
      if (current == null || current.priority < source.priority) {
        families[id] = source;
      }
    }
    return [
      for (final source in families.values)
        if (_definition(source) case final definition?) definition,
    ];
  }

  bool _eligible(ProviderRuleSource source) =>
      source.discovery != null && (allowDevelopment || !source.development);

  ProviderDefinition<RemoteBase>? _definition(ProviderRuleSource source) {
    final providerId = source.identity.providerId;
    try {
      final discovery = DiscoveryRules.fromJson(source.discovery!);
      final device = DeviceRules.fromJson(source.device ?? const {});
      final setup = device.setup;
      final policy = device.policy;
      final wake = device.wake;
      return ProviderDefinition<RemoteBase>(
        identifier: DeclarativeIdentifier(providerId, discovery, network),
        createController: createController,
        manualSetup: setup == null
            ? null
            : DeclarativeManualSetup(providerId, setup),
        connection: policy == null
            ? null
            : DeclarativeConnectionPolicy(discovery.category, policy),
        wake: wake == null ? null : _wake(source, providerId, wake),
      );
    } on FormatException {
      return null;
    } on RemoteException {
      return null;
    }
  }

  DeviceWakeProvider? _wake(
    ProviderRuleSource source,
    String providerId,
    Map<String, Object?> json,
  ) {
    if (json['kind'] != 'engine') {
      return DeclarativeWakeProvider(providerId, json);
    }
    final engine = engines.engine(source.engine);
    if (engine is! OfflineWakeEngine) {
      return null;
    }
    final mapping = IntegrationJson.object(json['mapping'], 'wake');
    return DeclarativeWakeProvider(
      providerId,
      json,
      engine: engine as OfflineWakeEngine,
      credentials: credentials,
      operation: engines.compile(
        source.engine,
        OperationMapping.fromJson('wake', mapping),
      ),
    );
  }
}
