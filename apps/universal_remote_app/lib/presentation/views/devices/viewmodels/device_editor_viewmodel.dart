import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

final class DeviceEditorViewModel {
  DeviceEditorViewModel({
    required this.factory,
    this.device,
    this.setups = const {},
    DeviceNetworkConfiguration configuration =
        const DeviceNetworkConfiguration(),
  }) {
    provider.value = device?.providerId ?? setups.keys.firstOrNull;
    name.text = device?.name ?? 'Living room TV';
    address.text = configuration.address;
    certificate.text = configuration.certificate;
    mac.text = configuration.mac;
    broadcast.text = configuration.broadcast;
    legacy.value = configuration.legacy;
    legacyPointer.value = configuration.allowInsecurePointer;
  }
  final ManualDeviceFactory factory;
  final Map<String, ManualDeviceSetup> setups;
  final provider = ValueNotifier<String?>(null);
  final RemoteDevice? device;
  final name = TextEditingController();
  final address = TextEditingController();
  final certificate = TextEditingController();
  final mac = TextEditingController();
  final broadcast = TextEditingController();
  final legacy = ValueNotifier(false);
  final legacyPointer = ValueNotifier(false);
  final error = ValueNotifier<String?>(null);
  Listenable get changes =>
      Listenable.merge([legacy, legacyPointer, error, provider]);
  bool get showsAdvancedSetup =>
      setups[provider.value]?.showsAdvancedSetup ?? true;
  bool get editing => device != null;
  void setLegacy(bool enabled) {
    legacy.value = enabled;
  }

  void setLegacyPointer(bool enabled) {
    legacyPointer.value = enabled;
  }

  RemoteDevice? submit() {
    try {
      final create = editing
          ? factory
          : setups[provider.value]?.factory ?? factory;
      return create(
        address: address.text,
        name: name.text,
        legacy: legacy.value,
        allowInsecurePointer: legacyPointer.value,
        certificate: certificate.text,
        mac: mac.text,
        broadcast: broadcast.text,
        existing: device,
      );
    } catch (exception) {
      error.value = _message(exception);
      return null;
    }
  }

  String _message(Object exception) {
    if (exception is RemoteException) {
      return exception.message;
    }
    if (exception is FormatException) {
      return exception.message;
    }
    return 'Check the connection details.';
  }

  void dispose() {
    name.dispose();
    address.dispose();
    certificate.dispose();
    mac.dispose();
    broadcast.dispose();
    legacy.dispose();
    legacyPointer.dispose();
    error.dispose();
    provider.dispose();
  }
}
