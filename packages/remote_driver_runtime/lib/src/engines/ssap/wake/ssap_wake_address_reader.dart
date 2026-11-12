import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/ssap.dart';
import 'package:remote_network/remote_network.dart';

/// Matches the current peer address to a reported interface before taking its MAC.
final class SsapWakeAddressReader {
  SsapWakeAddressReader(this.client, {this.service = defaultService});
  final SsapClient client;

  /// The connection-manager service queried for interface addresses.
  final String service;
  static const defaultService = 'com.webos.service.connectionmanager';
  static const _timeout = Duration(seconds: 1);
  Future<DeviceWakeAddress?> read(String host) async {
    try {
      final info = await client.request('$service/getinfo', timeout: _timeout);
      if (info['wifiInfo'] is! Map && info['wiredInfo'] is! Map) {
        return null;
      }
      final status = await _status();
      final addresses = <DeviceWakeAddress>[
        ?_interfaceMac(info['wifiInfo'], status['wifi'], host),
        ?_interfaceMac(info['wiredInfo'], status['wired'], host),
      ];
      return addresses.length == 1 ? addresses.single : null;
    } catch (_) {
      // Older firmware and restricted permissions leave the optional lookup unavailable.
      return null;
    }
  }

  Future<Map<String, Object?>> _status() async {
    try {
      return await client.request('$service/getStatus', timeout: _timeout);
    } on RemoteException catch (error) {
      if (error.code != 'unsupported') {
        rethrow;
      }
      return client.request('$service/getstatus', timeout: _timeout);
    }
  }

  static DeviceWakeAddress? _interfaceMac(
    Object? info,
    Object? status,
    String host,
  ) {
    if (info is! Map<Object?, Object?> || status is! Map<Object?, Object?>) {
      return null;
    }
    final interfaces = _rows(status['interfaces'] ?? status['interface']);
    final matched = interfaces
        .where((item) => _matches(item, host))
        .firstOrNull;
    if (matched != null) {
      final name = matched['name'] ?? matched['interfaceName'];
      if (name is! String) {
        return null;
      }
      final entry = _rows(info['interfaces'])
          .where((item) => item['name'] == name)
          .firstOrNull;
      final address = _address(entry?['macAddress'], matched, host);
      if (address != null) {
        return address;
      }
      if (!_matches(status, host) || status['interfaceName'] != name) {
        return null;
      }
    }
    if (!_matches(status, host)) {
      return null;
    }
    return _address(info['macAddress'], status, host);
  }

  static Iterable<Map<Object?, Object?>> _rows(Object? value) =>
      value is List ? value.whereType<Map<Object?, Object?>>() : const [];
  static bool _matches(Map<Object?, Object?> status, String host) =>
      status['state'] == 'connected' && status['ipAddress'] == host;
  static DeviceWakeAddress? _address(
    Object? value,
    Map<Object?, Object?> status,
    String host,
  ) {
    final mac = value is String ? normalizeMacAddress(value) : null;
    if (mac == null) {
      return null;
    }
    final mask = status['netmask'];
    return DeviceWakeAddress(
      mac,
      broadcastAddress: ipv4BroadcastAddress(
        host,
        mask is String ? mask : null,
      ),
    );
  }
}
