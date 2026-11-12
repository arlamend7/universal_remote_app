import '../../device.dart';
import '../../discovery/provider_identifier.dart';
import '../../provider.dart';
import '../../remote_base.dart';

final class ProviderDefinition<T extends RemoteBase> {
  ProviderDefinition({
    required this.identifier,
    required this.createController,
    this.manualSetup,
    this.wake,
    this.connection,
  }) {
    if (identifier.id.trim().isEmpty) {
      throw ArgumentError('Provider ID must be nonempty.');
    }
  }

  String get id => identifier.id;
  final ProviderIdentifier identifier;
  final T Function(RemoteDevice) createController;
  final ManualDeviceProvider? manualSetup;
  final DeviceWakeProvider? wake;
  final DeviceConnectionPolicy? connection;
}
