import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

final class DeviceEditorViewModel {
  DeviceEditorViewModel({
    required this.factory,
    this.device,
    this.identifyAddress,
    Map<String, ManualDeviceSetup> setups = const {},
    this.currentSetups,
    DeviceNetworkConfiguration configuration =
        const DeviceNetworkConfiguration(),
  }) : _setups = setups {
    provider.value =
        device?.providerId ??
        (identifyAddress == null ? setups.keys.firstOrNull : null);
    name.text = device?.name ?? 'Living room TV';
    address.text = configuration.address;
    certificate.text = configuration.certificate;
    mac.text = configuration.mac;
    broadcast.text = configuration.broadcast;
    legacy.value = configuration.legacy;
    legacyPointer.value = configuration.allowInsecurePointer;
  }
  final ManualDeviceFactory factory;
  final Future<List<String>> Function(String, DiscoveryCancellation)?
  identifyAddress;
  final checking = ValueNotifier(false);
  DiscoveryCancellation? _scan;
  bool _disposed = false;
  final Map<String, ManualDeviceSetup> _setups;
  final Map<String, ManualDeviceSetup> Function()? currentSetups;
  Map<String, ManualDeviceSetup> get setups => currentSetups?.call() ?? _setups;
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
      Listenable.merge([legacy, legacyPointer, error, provider, checking]);
  bool get showsAdvancedSetup =>
      setups[provider.value]?.showsAdvancedSetup ??
      (editing || identifyAddress == null);
  bool get editing => device != null;
  void setLegacy(bool enabled) {
    legacy.value = enabled;
  }

  void setLegacyPointer(bool enabled) {
    legacyPointer.value = enabled;
  }

  Future<RemoteDevice?> submit() async {
    if (checking.value || _disposed) {
      return null;
    }
    error.value = null;
    if (editing || provider.value != null || identifyAddress == null) {
      return _create(provider.value);
    }
    return _detect();
  }

  Future<RemoteDevice?> _detect() async {
    final token = _scan = DiscoveryCancellation();
    final host = address.text.trim();
    checking.value = true;
    try {
      final matches = await identifyAddress!(host, token);
      if (_disposed || address.text.trim() != host) {
        return null;
      }
      if (matches.length == 1) {
        return _create(matches.single);
      }
      error.value = matches.isEmpty
          ? 'Could not detect the TV platform. Choose it manually and try again.'
          : 'More than one platform matched. Choose the platform for your TV.';
      return null;
    } catch (exception) {
      if (!_disposed) {
        error.value = _message(exception);
      }
      return null;
    } finally {
      token.cancel();
      _scan = null;
      if (!_disposed) {
        checking.value = false;
      }
    }
  }

  RemoteDevice? _create(String? selectedProvider) {
    try {
      final create = editing
          ? factory
          : setups[selectedProvider]?.factory ?? factory;
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
    _disposed = true;
    _scan?.cancel();
    checking.dispose();
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
