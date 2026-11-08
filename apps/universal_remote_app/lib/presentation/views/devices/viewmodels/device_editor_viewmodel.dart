import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

final class DeviceEditorViewModel {
  DeviceEditorViewModel({
    required this.factory,
    this.device,
    DeviceNetworkConfiguration configuration =
        const DeviceNetworkConfiguration(),
  }) {
    name.text = device?.name ?? 'Living room TV';
    address.text = configuration.address;
    certificate.text = configuration.certificate;
    mac.text = configuration.mac;
    broadcast.text = configuration.broadcast;
    legacy.value = configuration.legacy;
    legacyPointer.value = configuration.allowInsecurePointer;
  }
  final ManualDeviceFactory factory;
  final RemoteDevice? device;
  final name = TextEditingController();
  final address = TextEditingController();
  final certificate = TextEditingController();
  final mac = TextEditingController();
  final broadcast = TextEditingController();
  final legacy = ValueNotifier(false);
  final legacyPointer = ValueNotifier(false);
  final error = ValueNotifier<String?>(null);
  Listenable get changes => Listenable.merge([legacy, legacyPointer, error]);
  bool get editing => device != null;
  void setLegacy(bool enabled) {
    legacy.value = enabled;
  }

  void setLegacyPointer(bool enabled) {
    legacyPointer.value = enabled;
  }

  RemoteDevice? submit() {
    try {
      return factory(
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
  }
}
